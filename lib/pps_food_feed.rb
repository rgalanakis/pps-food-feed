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
  HOMEPAGE_HOST = "ppsmenus.net"
  HOMEPAGE = "https://#{HOMEPAGE_HOST}".freeze
  AUTHOR = "rob.galanakis@lithic.tech"
  ROOT_DIR = Pathname(__dir__).parent
  CSV_DIR = ROOT_DIR.join("csvs")
  STATIC_DIR = ROOT_DIR.join("static")
  FEEDS_DIR = STATIC_DIR.join("feeds")
  META_DIR = ROOT_DIR.join("meta")
  PDF_DIR = ROOT_DIR.join("pdfs")

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
    # Modify this if serving from not the homepage.
    setting :site_host,
            HOMEPAGE,
            key: "SITE_HOST"
  end

  class << self
    def run
      MenuFetcher.new.run
      CsvConverter.new.run
      IcsConverter.new.run
      IndexGenerator.new.run
    end

    def load_app
      Appydays::Loggable.configure_12factor(format: self.log_format, application: APPLICATION_NAME)
    end

    def clean_filename_part(s)
      r = s.gsub("/", ", ") # Would break pathing
      r.gsub!(".", "") # Not currently used in menus, but would break us if it were
      r.gsub!("|", "-") # Not currently used in menus, but would break us if it were
      return r
    end

    # See +menu_name_and_month+ to get the month and name back.
    def menu_filename(dir, month, name, hash, ext)
      raise "hash must be an md5" unless /^[a-z\d]+$/.match?(hash)
      n = self.clean_filename_part(name)
      m = self.clean_filename_part(month)
      return dir.join("#{n} | #{m} | #{hash}#{ext}")
    end

    # See +menu_filename+ to create this name.
    def parse_menu_name_month_hash(p)
      return File.basename(p, ".*").split(" | ")
    end
  end
end

require_relative "pps_food_feed/menu_fetcher"
require_relative "pps_food_feed/csv_converter"
require_relative "pps_food_feed/ics_converter"
require_relative "pps_food_feed/index_generator"
