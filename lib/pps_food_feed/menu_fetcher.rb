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

        raw_menu_name = a.parent.text.strip
        raw_menu_month = section_title.text.strip
        pdf_filename = self.pdf_filename(raw_menu_month, raw_menu_name)
        png_filename = self.png_filename(raw_menu_month, raw_menu_name)
        menu_name, menu_month = PpsFoodFeed.menu_name_and_month(pdf_filename)
        menu_rel_link = a.attr(:href)
        menu_url = PPS_ROOT + menu_rel_link
        next if png_filename.exist?

        meta.set(menu_name, menu_month, :url, menu_url)
        meta.set(menu_name, menu_month, :fetched_at, now)
        self.logger.info("fetching_menu_pdf", menu_url:)
        pdf_resp = HTTPX.get(menu_url).raise_for_status
        File.write(pdf_filename, pdf_resp.body.read)
        pdf_im = Magick::Image.read(pdf_filename)
        self.logger.info("converting_to_jpg", png_filename:)
        pdf_im.first.write(png_filename)
      end
      meta.save
      return menu_resp
    end

    def pdf_filename(month, name) = PpsFoodFeed.menu_filename(PpsFoodFeed::PDF_DIR, month, name, ".pdf")
    def png_filename(month, name) = PpsFoodFeed.menu_filename(PpsFoodFeed::PNG_DIR, month, name, ".png")
  end
end
