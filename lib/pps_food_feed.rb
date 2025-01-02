# frozen_string_literal: true

# Find each menu section accordion
# The accordion text is the date
# Find each link under the accordion
# Each of those is a menu
# The link is the PDF link, the <li> text is the feed name
# Based on the feed name, see if we can figure out a prompt
# Download the PDF
# Send it to Gemini with the prompt
# Get a CSV back
# Convert the CSV to ICS

require "appydays/configurable"
require "appydays/loggable"

class PpsFoodFeed
  VERSION = "0.0.1"
  APPLICATION_NAME = "PPS Food Feed"
  CSV_DIR = Pathname(__dir__).parent.join("csvs")
  FEEDS_DIR = Pathname(__dir__).parent.join("feeds")
  PDF_DIR = Pathname(__dir__).parent.join("pdfs")
  PNG_DIR = Pathname(__dir__).parent.join("pngs")

  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:ppsfoodfeed) do
    setting :log_level_override,
            nil,
            key: "LOG_LEVEL",
            side_effect: ->(v) { Appydays::Loggable.default_level = v if v }
    setting :log_format,
            :json_trunc,
            key: "LOG_FORMAT"
    setting :anthropic_api_key,
            "unsetkey",
            key: "ANTHROPIC_API_KEY"
  end

  class << self
    def run
      f = self.new
      f.fetch_menus
      f.convert_csvs
      f.convert_ics
    end

    def load_app
      Appydays::Loggable.configure_12factor(format: self.log_format, application: APPLICATION_NAME)
    end

    # See +menu_name_and_month+ to get the month and name back.
    def menu_filename(dir, month, name, ext)
      name = name.gsub("/", ", ")
      return dir.join("#{name} - #{month}#{ext}")
    end

    # See +menu_filename+ to create this name.
    def menu_name_and_month(p)
      return File.basename(p, ".*").split(" - ")
    end
  end

  def fetch_menus = MenuFetcher.new.run
  def convert_csvs = CsvConverter.new.run
  def convert_ics = IcsConverter.new.run
end

require_relative "pps_food_feed/menu_fetcher"
require_relative "pps_food_feed/csv_converter"
require_relative "pps_food_feed/ics_converter"
