# frozen_string_literal: true

require "fileutils"
require "httpx"
require "nokogiri"
require "rmagick"

require_relative "meta"

class PpsFoodFeed
  class MenuFetcher
    include Appydays::Loggable

    USER_AGENT = "PPS Food Feed/#{PpsFoodFeed::VERSION} https://ppsfoodfeed.net".freeze
    PPS_ROOT = "https://www.pps.net"
    MENU_URL = "#{PPS_ROOT}/Page/214".freeze

    def run
      meta = PpsFoodFeed::Meta.load
      FileUtils.mkdir_p(PpsFoodFeed::PDF_DIR)
      FileUtils.mkdir_p(PpsFoodFeed::PNG_DIR)
      now = Time.now
      menu_resp = HTTPX.get(MENU_URL).raise_for_status
      menu_html = menu_resp.to_s
      menu_doc = Nokogiri::HTML(menu_html)
      menu_anchors = menu_doc.xpath("/html/body//li/a[contains(@href,'menu%20calendars')]")
      self.logger.info("found_menus", menu_count: menu_anchors.count)
      menu_anchors.each do |a|
        section_root = a.parent&.parent&.parent&.parent
        raise RuntimeError if section_root.nil?
        section_title = section_root.children.find { |c| c.name == "h1" }
        raise RuntimeError if section_title.nil?

        menu_rel_link = a.attr(:href)
        menu_url = PPS_ROOT + menu_rel_link

        menu_name = PpsFoodFeed.clean_filename_part(a.parent.text.strip)
        menu_month = PpsFoodFeed.clean_filename_part(section_title.text.strip)
        headers = {}
        if (stored_etag = meta.get(menu_name, menu_month, :etag))
          headers["If-None-Match"] = stored_etag
        end
        pdf_resp = HTTPX.get(menu_url, headers:).raise_for_status
        if pdf_resp.status == 304
          self.logger.debug("menu_pdf_304", menu_url:, headers:)
          next
        end

        self.logger.info("fetched_menu_pdf", menu_url:, headers:)
        pdf_resp_etag = pdf_resp.headers["etag"]
        pdf_bytes = pdf_resp.body.read
        # Note that the etag may change, even when the content is the same (it's just up to Cloudflare),
        # so we MUST hash the file contents to get a persistent 'id' of the PDF.
        pdf_hash = Digest::SHA256.hexdigest(pdf_bytes)[..8]
        pdf_filename = self.pdf_filename(menu_month, menu_name, pdf_hash)
        if File.exist?(pdf_filename)
          self.logger.debug("menu_pdf_body_unchanged", menu_url:, pdf_hash:)
          next
        end

        png_filename = self.png_filename(menu_month, menu_name, pdf_hash)
        meta.set(menu_name, menu_month, :url, menu_url)
        meta.set(menu_name, menu_month, :fetched_at, now)
        meta.set(menu_name, menu_month, :etag, pdf_resp_etag)
        meta.set(menu_name, menu_month, :latest_hash, pdf_hash)
        File.write(pdf_filename, pdf_bytes)
        pdf_im = Magick::Image.read(pdf_filename)
        self.logger.info("converting_to_png", png_filename:)
        pdf_im.first.write(png_filename)
      end
      meta.save
      return menu_resp
    end

    def pdf_filename(month, name, hash) = PpsFoodFeed.menu_filename(PpsFoodFeed::PDF_DIR, month, name, hash, ".pdf")
    def png_filename(month, name, hash) = PpsFoodFeed.menu_filename(PpsFoodFeed::PNG_DIR, month, name, hash, ".png")
  end
end
