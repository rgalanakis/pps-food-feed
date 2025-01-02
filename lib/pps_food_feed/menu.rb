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
        Only include the CSV in your response.
        The CSV must be property escaped.
      TXT
      return s
    end
  end
end
