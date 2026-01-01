# frozen_string_literal: true

require "fileutils"
require "httpx"
require "nokogiri"

require_relative "meta"

class PpsFoodFeed
  class MenuFetcher
    include Appydays::Loggable

    USER_AGENT = "PPS Food Feed/#{PpsFoodFeed::VERSION} https://ppsfoodfeed.net".freeze
    PPS_ROOT = "https://www.pps.net"
    MENU_URL = "#{PPS_ROOT}/departments/nutrition-services/menus".freeze

    def run
      meta = PpsFoodFeed::Meta.load
      FileUtils.mkdir_p(PpsFoodFeed::PDF_DIR)
      now = Time.now
      menu_resp = HTTPX.get(MENU_URL).raise_for_status
      menu_html = menu_resp.to_s
      menu_doc = Nokogiri::HTML(menu_html)
      menu_anchors = menu_doc.xpath("/html/body//li/a[contains(@data-file-name,'.pdf')]")
      self.logger.info("found_menus", menu_count: menu_anchors.count)
      menu_anchors.each do |a|
        section_root = a.parent&.parent&.parent&.parent&.parent&.parent
        raise RuntimeError if section_root.nil?
        section_title = section_root.children.find { |c| c.name == "header" }&.children&.find { |c| c.name == "h2" }
        raise "could not find section title (month/year) for menu link" if section_title.nil?

        menu_rel_link = a.attr(:href)
        menu_redirect_url = PPS_ROOT + menu_rel_link

        menu_name = PpsFoodFeed.clean_filename_part(a.parent.text)
        menu_month = PpsFoodFeed.clean_filename_part(section_title.text)
        headers = {}
        if (stored_etag = meta.get(menu_name, menu_month, :etag))
          headers["If-None-Match"] = stored_etag
        end
        # The URL is a CMS url, which returns a redirect for the actual PDF file.
        # In order to use ETag headers, we need to handle the redirect ourselves
        # (HTTPX plugin intentionally would not reissue the If-None-Match).
        # This is obviously brittle, since it hard-codes the redirect flow.
        # But the redirect flow seems like reasonable CMS behavior, so I think it's okay,
        # and we assert if our assumptions are violated as we do elsewhere
        # (hardcoding HTML structure is also brittle!).
        redirect_resp = HTTPX.get(menu_redirect_url).raise_for_status
        raise "expected redirect response for #{menu_redirect_url}, got #{redirect_resp}" unless
          redirect_resp.status >= 300
        menu_pdf_url = redirect_resp.headers["location"]
        pdf_resp = HTTPX.get(menu_pdf_url, headers:).raise_for_status
        if pdf_resp.status == 304
          self.logger.debug("menu_pdf_304", menu_url: menu_pdf_url, headers:)
          next
        end

        self.logger.info("fetched_menu_pdf", menu_url: menu_pdf_url, headers:)
        pdf_resp_etag = pdf_resp.headers["etag"]
        pdf_bytes = pdf_resp.body.read
        # Note that the etag may change, even when the content is the same (it's just up to Cloudflare),
        # so we MUST hash the file contents to get a persistent 'id' of the PDF.
        pdf_hash = Digest::SHA256.hexdigest(pdf_bytes)[..8]
        pdf_filename = self.pdf_filename(menu_month, menu_name, pdf_hash).to_s

        # Always update the url, in case internal redirects changed.
        # If the URL is the same, meta won't change and we won't have spurious PR diffs.
        meta.set(menu_name, menu_month, :url, menu_pdf_url)
        # It's possible ETags changed even if the file hasn't,
        # so make sure to always update meta with a new one,
        # so we don't keep re-fetching. Other data only needs to be updated when the pdf changes.
        # For example, we don't want to update fetched_at, or we'd have spurious changes.
        # If the etag is the same, meta won't be updated so we won't have spurious PR diffs.
        meta.set(menu_name, menu_month, :etag, pdf_resp_etag)

        if File.exist?(pdf_filename)
          self.logger.debug("menu_pdf_body_unchanged", menu_url: menu_pdf_url, pdf_hash:)
          next
        end

        meta.set(menu_name, menu_month, :fetched_at, now)
        meta.set(menu_name, menu_month, :latest_hash, pdf_hash)
        File.binwrite(pdf_filename, pdf_bytes)
      end
      meta.save
      return menu_resp
    end

    def pdf_filename(month, name, hash) = PpsFoodFeed.menu_filename(PpsFoodFeed::PDF_DIR, month, name, hash, ".pdf")
  end
end
