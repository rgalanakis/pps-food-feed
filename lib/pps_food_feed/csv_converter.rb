# frozen_string_literal: true

require "appydays/loggable"
require "base64"
require "httpx"

class PpsFoodFeed
  class CsvConverter
    include Appydays::Loggable

    ANTHROPIC_MODEL = "claude-3-5-sonnet-20241022"

    def run
      FileUtils.mkdir_p(PpsFoodFeed::CSV_DIR)
      PpsFoodFeed::PDF_DIR.children.each do |pdf|
        name, month = PpsFoodFeed.menu_name_and_month(pdf)
        csv_filename = PpsFoodFeed.menu_filename(PpsFoodFeed::CSV_DIR, month, name, ".csv")
        next if csv_filename.exist?
        prompt = PROMPT_MAP.fetch(name, DEFAULT_PROMPT)
        self.logger.info("analyzing_pdf", name:, month:)
        resp = self.call_anthropic(pdf, prompt.to_s)
        body = resp.to_s
        json_body = JSON.parse(body)
        csv_text = json_body.fetch("content").first.fetch("text")
        File.write(csv_filename, csv_text)
      end
    end

    def call_anthropic(pdf_filename, prompt)
      raise RuntimeError if PpsFoodFeed.anthropic_api_key.empty?

      base64_pdf = Base64.strict_encode64(File.binread(pdf_filename))
      bod = {
        model: ANTHROPIC_MODEL,
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: [
              {type: "text", text: prompt},
              # {
              #   type: "base64",
              #   media_type: 'image/png',
              #   data: base64_image,
              # },
              {
                type: "document",
                source: {
                  type: "base64",
                  media_type: "application/pdf",
                  data: base64_pdf,
                },
              },
            ],
          },
        ],
      }
      resp = HTTPX.post(
        "https://api.anthropic.com/v1/messages",
        body: bod.to_json,
        headers: {
          "Content-Type" => "application/json",
          "X-Api-Key" => PpsFoodFeed.anthropic_api_key,
          "Anthropic-Version" => "2023-06-01",
        },
      )
      resp.raise_for_status
      return resp
    end

    class Prompt
      def initialize(columns, instructions="")
        @columns = ["month", "year", "day of month", "early release"] + columns
        @instructions = instructions
      end

      def to_s
        cols = @columns.join(", ")
        s = <<~TXT
          The attached file is a calendar.
          #{@instructions}
          Read it and output a CSV file with the following columns: #{cols}.
          If the cell contains 'Schools Closed' or 'No School for Students', do not output a row for that day.
          If the day includes the text 'Early Release', the 'early release' column should be 'true', otherwise it should be empty.
          Only include the CSV in your response.
          The CSV must be property escaped.
        TXT
        return s
      end
    end

    BLPrompt = Prompt.new(["breakfast", "lunch"], <<~TXT)
      The cell for each day contains text including 'Schools Closed' or 'No School for Students', or it contains two rows.
      If it contains two rows, the top row is breakfast for that day, the bottom row is lunch for that day.
    TXT
    BLSPrompt = Prompt.new(["breakfast", "lunch", "snack"], <<~TXT)
      The cell for each day contains text including 'Schools Closed' or 'No School for Students', or it contains three rows.
      If it contains three rows, the top row is breakfast for that day, the middle row is lunch for that day, the bottom row is snack for that day.
    TXT
    DEFAULT_PROMPT = Prompt.new(["meal"], <<~TXT)
      The cell for each day contains text including 'Schools Closed' or 'No School for Students', or it contains the meal for that day.
      The meal may span multiple lines, or include multiple items, such as "Burrito Bar" and "Pizza" for the same day.
      In this case, the meal should be output as "Burrito Bar, Pizza".
    TXT

    PROMPT_MAP = {
      "Breakfast, Lunch (Access, CTP)" => BLPrompt,
      "Early Learners" => BLSPrompt,
      "Head Start (Creston)" => BLSPrompt,
      "Head Start (MECP)" => BLSPrompt,
      "Head Start, Pre-K" => BLSPrompt,
      "MECP" => BLSPrompt,
      "Neighborhood House" => BLPrompt,
    }.freeze
  end
end
