# frozen_string_literal: true

class PpsFoodFeed
  class Menu
    attr_accessor :meal_columns

    def initialize(columns, instructions="")
      @meal_columns = columns
      @all_columns = ["month", "year", "day of month", "early release"] + columns
      @instructions = instructions
    end

    def prompt
      cols = @all_columns.join(", ")
      s = <<~TXT
        The attached file is a calendar.
        #{@instructions}
        Read it and output a CSV file with the following columns: #{cols}.
        If the cell contains 'Schools Closed' or 'No School for Students', do not output a row for that day.
        If the day includes the text 'Early Release', the 'early release' column should be 'true', otherwise it should be empty.
        The CSV in your response should be proper CSV (that is, not a Markdown code block with CSV),
        and it must have correct CSV escaping.
      TXT
      return s
    end
  end
end
