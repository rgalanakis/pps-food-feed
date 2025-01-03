# frozen_string_literal: true

require "appydays/loggable"
require "csv"
require "digest"
require "fileutils"
require "icalendar"

class PpsFoodFeed
  class IcsConverter
    include Appydays::Loggable

    def run
      FileUtils.mkdir_p(PpsFoodFeed::FEEDS_DIR)
      @meta = PpsFoodFeed::Meta.load
      groups = PpsFoodFeed::CSV_DIR.children.group_by { |f| PpsFoodFeed.menu_name_and_month(f)[0] }
      groups.each do |menu, csv_files|
        self.create_ical(menu, csv_files)
      end
    end

    def create_ical(menu_name, csv_files)
      menu = PpsFoodFeed::Menus.get(menu_name)
      cal = Icalendar::Calendar.new
      cal.prodid = "#{PpsFoodFeed::HOMEPAGE}"
      cal.publish
      csv_files.each do |csv_file|
        _, menu_month = PpsFoodFeed.menu_name_and_month(csv_file)
        CSV.foreach(csv_file, headers: true, header_converters: :symbol, converters: :all) do |row|
          row = row.to_h
          d = "#{row[:month]} #{row[:day_of_month]} #{row[:year]}"
          d = Date.parse(d)
          d = Icalendar::Values::Date.new(d)
          lastmod = Time.parse(@meta.get(menu_name, menu_month, :fetched_at))
          cal.event do |e|
            e.uid = self.uid(menu_name, menu_month, row)
            e.dtstart = d
            e.dtend = d
            e.last_modified = lastmod
            e.dtstamp = lastmod
            e.summary = self.summary(menu, row)
            e.description = self.description(menu, menu_name, menu_month, row)
          end
        end
      end
      ical_filename = PpsFoodFeed::FEEDS_DIR.join(menu_name + ".ics")
      File.write(ical_filename, cal.to_ical)
      self.logger.info("write_ics", menu: menu_name, events: cal.events.count)
    end

    def uid(menu_name, menu_month, row)
      h = Digest::MD5.new
      h << menu_name
      h << menu_month
      h << JSON.generate(row)
      return h.hexdigest
    end

    def summary(menu, row)
      mc = menu.meal_columns.map(&:to_sym)
      title = mc.size == 1 ? row.fetch(mc.first) : mc.map { |c| row.fetch(c) }.join(", ")
      title += " (Early Release)" if row.fetch(:early_release)
      return title
    end

    def description(menu, menu_name, menu_month, row)
      mc = menu.meal_columns.map(&:to_sym)
      if mc.size == 1
        d = "Today's meal is: #{row.fetch(mc.first)}"
      else
        parts = mc.map { |c| "#{self.titleize(c)}: #{row.fetch(c)}" }.join("\n")
        d = "Served today:\n#{parts}"
      end
      url = @meta.get(menu_name, menu_month, :url)
      d += "\n\nTo see this month's menu, go to <a href=\"#{url}\">#{menu_month} - #{menu_name}</a>"
      d += "\n\nFeed generated by #{PpsFoodFeed::HOMEPAGE}. To report a problem, email #{PpsFoodFeed::AUTHOR}"
      return d
    end

    def titleize(s)
      return s[0].upcase + s[1..]
    end
  end
end
