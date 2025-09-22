# frozen_string_literal: true

require "appydays/loggable"
require "base64"
require "fileutils"
require "httpx"

require_relative "menus"

class PpsFoodFeed
  class CsvConverter
    include Appydays::Loggable

    ANTHROPIC_MODEL = "claude-sonnet-4-20250514"

    def run
      FileUtils.mkdir_p(PpsFoodFeed::CSV_DIR)
      PpsFoodFeed::PDF_DIR.children.each do |pdf|
        name, month, hash = PpsFoodFeed.parse_menu_name_month_hash(pdf)
        csv_filename = PpsFoodFeed.menu_filename(PpsFoodFeed::CSV_DIR, month, name, hash, ".csv")
        next if csv_filename.exist?
        menu = PpsFoodFeed::Menus.get(name)
        self.logger.info("analyzing_pdf", name:, month:)
        resp = self.call_anthropic(pdf, menu.prompt)
        body = resp.to_s
        json_body = JSON.parse(body)
        csv_text = json_body.fetch("content").first.fetch("text")
        raise "LLM call did not convert to CSV properly.\nPrompt: #{menu.prompt}\nResult: #{json_body}" unless
          CSV.parse(csv_text).first.first == "month"
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
  end
end
