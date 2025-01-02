# frozen_string_literal: true

class PpsFoodFeed
  class MenuFetcher
    include Appydays::Loggable

    USER_AGENT = "PPS Food Feed/#{PpsFoodFeed::VERSION} https://ppsfoodfeed.net".freeze
    PPS_ROOT = "https://www.pps.net"
    MENU_URL = "#{PPS_ROOT}/Page/214".freeze

    def run
      FileUtils.mkdir_p(PpsFoodFeed::PDFS_DIR)
      FileUtils.mkdir_p(PpsFoodFeed::PNGS_DIR)
      menu_resp = HTTPX.get(MENU_URL).raise_for_status
      menu_html = menu_resp.to_s
      menu_doc = Nokogiri::HTML(menu_html)
      menu_anchors = menu_doc.xpath("/html/body//li/a[contains(@href,'menu%20calendars')]")
      self.logger.info("found_menus", menu_count: menu_anchors.count)
      menu_anchors.each do |a|
        menu_name = a.parent.text.strip
        section_root = a.parent&.parent&.parent&.parent
        raise RuntimeError if section_root.nil?
        section_title = section_root.children.find { |c| c.name == "h1" }
        raise RuntimeError if section_title.nil?
        menu_month = section_title.text.strip
        pdf_filename = self.pdf_filename(menu_month, menu_name)
        png_filename = self.png_filename(menu_month, menu_name)
        next if png_filename.exist?

        menu_rel_link = a.attr(:href)
        menu_url = PPS_ROOT + menu_rel_link
        self.logger.info("fetching_menu_pdf", menu_url:)
        pdf_resp = HTTPX.get(menu_url).raise_for_status
        File.write(pdf_filename, pdf_resp.body.read)
        pdf_im = Magick::Image.read(pdf_filename)
        self.logger.info("converting_to_jpg", png_filename:)
        pdf_im.first.write(png_filename)
      end
    end

    def pdf_filename(month, name) = menu_filename(PpsFoodFeed::PDFS_DIR, month, name, ".pdf")
    def png_filename(month, name) = menu_filename(PpsFoodFeed::PNGS_DIR, month, name, ".png")

    # See +menu_name_and_month+ to get the month and name back.
    def menu_filename(dir, month, name, ext)
      name = name.gsub("/", ", ")
      return dir.join("#{name} - #{month}#{ext}")
    end

    # See +menu_filename+ to create this name.
    def menu_name_and_month(p)
      return File.basename(p, ".*").split(" - ")
    end
  end
end
