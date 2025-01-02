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
require "fileutils"
require "httpx"
require "nokogiri"
require "RMagick"

class PpsFoodFeed
  VERSION = "0.0.1"
  APPLICATION_NAME = "PPS Food Feed"
  FEEDS_DIR = Pathname(__dir__).parent.join("feeds")
  PDFS_DIR = Pathname(__dir__).parent.join("pdfs")
  PNGS_DIR = Pathname(__dir__).parent.join("pngs")

  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:ppsfoodfeed) do
    setting :log_level_override,
            nil,
            key: "LOG_LEVEL",
            side_effect: ->(v) { Appydays::Loggable.default_level = v if v }
    setting :log_format, :json_trunc
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
  end

  def fetch_menus = MenuFetcher.new.run
  def convert_csvs = CsvConverter.new.run
  def convert_ics = IcsConverter.new.run
end

require_relative "pps_food_feed/menu_fetcher"
require_relative "pps_food_feed/csv_converter"
require_relative "pps_food_feed/ics_converter"
