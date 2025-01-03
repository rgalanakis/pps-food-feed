# frozen_string_literal: true

require "erb"

class PpsFoodFeed
  class IndexGenerator
    include Appydays::Loggable

    DAY = 60 * 60 * 24

    def run
      @links = []
      meta = PpsFoodFeed::Meta.load
      meta.each do |name, months|
        next unless self.recent?(months)
        escaped_name = URI.encode_www_form_component(name)
        href = "#{PpsFoodFeed.site_host}/static/feeds/#{escaped_name}.ics"
        @links << {name:, href:}
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
