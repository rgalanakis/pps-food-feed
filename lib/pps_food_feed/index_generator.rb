# frozen_string_literal: true

require "erb"

class PpsFoodFeed
  class IndexGenerator
    include Appydays::Loggable

    DAY = 60 * 60 * 24

    def run
      author = PpsFoodFeed::AUTHOR
      homepage = PpsFoodFeed::HOMEPAGE
      meta = PpsFoodFeed::Meta.load

      links = []
      meta.each do |name, months|
        next unless self.recent?(months)
        href = "/feeds/#{name}.ics"
        links << {href:, name:}
      end
      links.sort_by! { |li| li[:name] }
      t = ERB.new(File.read(PpsFoodFeed::ROOT_DIR.join("site", "index.html.erb")))
      File.write(PpsFoodFeed::ROOT_DIR.join("index.html"), t.result(binding))
    end

    def recent?(months)
      recent = Time.now - (60 * DAY)
      months.each_value do |month|
        fetched = Time.parse(month.fetch("fetched_at"))
        return true if fetched > recent
      end
      return false
    end
  end
end
