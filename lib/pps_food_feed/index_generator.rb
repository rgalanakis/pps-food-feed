# frozen_string_literal: true

require "erb"
require "ostruct"
require "rqrcode"

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
        slug = f
        attachment_filename = name.gsub(/[^\w ]+/, "").gsub(" ", "-")
        path = "/static/feeds/#{f}"
        href = "#{PpsFoodFeed.site_host}#{path}"
        webcal_href = href.gsub(/^(https|http):/, "webcal:")
        inline_svg = RQRCode::QRCode.new(href).as_svg(viewbox: true)
        webcal_svg = RQRCode::QRCode.new(webcal_href).as_svg(viewbox: true)
        # See https://til.simonwillison.net/ics/google-calendar-ics-subscribe-link
        google_href = "https://calendar.google.com/calendar/u/0/r?cid=#{URI.encode_uri_component(href)}"
        google_svg = RQRCode::QRCode.new(google_href).as_svg(viewbox: true)
        @links << {
          name:,
          slug:,
          attachment_filename:,
          path:,
          inline_href: href,
          inline_svg:,
          google_href:,
          google_svg:,
          webcal_href:,
          webcal_svg:,
          k8: ["Breakfast (All Grades)", "Lunch (K5, K8, MS)"].include?(name),
          hs: ["Breakfast (All Grades)", "Lunch (HS)"].include?(name),
        }
      end
      @links.sort_by! { |li| li[:name] }
      gen_html
      gen_netlify_config
    end

    def gen_html
      vars = {
        author: PpsFoodFeed::AUTHOR,
        homepage: PpsFoodFeed::HOMEPAGE,
        k8_link: "/k8.html",
        hs_link: "/hs.html",
      }
      render_and_write("index.html.erb", "index.html", **vars, links: @links)
      render_and_write("index.html.erb", "k8.html", **vars, limited: true, links: @links.select { |li| li[:k8] })
      render_and_write("index.html.erb", "hs.html", **vars, limited: true, links: @links.select { |li| li[:hs] })
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
      render_and_write("headers.erb", "_headers", links: @links)
      render_and_write("redirects.erb", "_redirects", links: @links)
    end

    def render_and_write(erb, path, **vars)
      ctx = OpenStruct.new(vars)
      t = ERB.new(File.read(PpsFoodFeed::ROOT_DIR.join("site", erb)))
      html = t.result(ctx.instance_eval { binding })
      html.strip!
      html << "\n"
      File.write(PpsFoodFeed::ROOT_DIR.join(path), html)
    end
  end
end
