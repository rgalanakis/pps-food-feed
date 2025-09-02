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
        ical_entry = months.delete("_")
        next unless self.recent?(months)
        f = ical_entry.fetch("ical_filename")
        path = "/static/feeds/#{f}"
        inline_path = "/static/feeds/inline/#{f}"
        href = "#{PpsFoodFeed.site_host}#{path}"
        @links << {name:, href:, path:, inline_path:}
      end
      @links.sort_by! { |li| li[:name] }
      gen_index
      gen_netlify_config
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

    def gen_netlify_config
      render_and_write("headers.erb", "_headers")
      render_and_write("redirects.erb", "_redirects")
    end

    def render_and_write(erb, path)
      links = @links
      t = ERB.new(File.read(PpsFoodFeed::ROOT_DIR.join("site", erb)))
      html = t.result(binding)
      html.strip!
      html << "\n"
      File.write(PpsFoodFeed::ROOT_DIR.join(path), html)
    end
  end
end
