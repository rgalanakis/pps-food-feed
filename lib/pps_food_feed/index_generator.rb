# frozen_string_literal: true

require "erb"

class PpsFoodFeed
  class IndexGenerator
    include Appydays::Loggable

    DAY = 60 * 60 * 24

    def run
      @links = []
      meta = PpsFoodFeed::Meta.load
      meta.each do |name, h|
        next unless self.recent?(h)
        f = h.fetch("_").fetch("ical_filename")
        path = "/static/feeds/#{f}"
        href = "#{PpsFoodFeed.site_host}#{path}"
        @links << {name:, href:, path:}
      end
      @links.sort_by! { |li| li[:name] }
      gen_index
      gen_headers
    end

    def gen_index
      author = PpsFoodFeed::AUTHOR
      homepage = PpsFoodFeed::HOMEPAGE
      links = @links
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

    def gen_headers
      links = @links
      t = ERB.new(File.read(PpsFoodFeed::ROOT_DIR.join("site", "headers.erb")))
      File.write(PpsFoodFeed::ROOT_DIR.join("_headers"), t.result(binding))
    end
  end
end
