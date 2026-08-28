# Fetches the text content of a bookmarked URL for AI summarization. Distinct
# from UrlMetadataFetcher (which only grabs <title> synchronously at create
# time): this fetches a fuller body of text and is meant to run from a
# background job. Never raises; returns nil on any failure or when there
# isn't enough usable text to summarize.
class BookmarkContentFetcher
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 5
  USER_AGENT = "JeffreyAppsBot/1.0 (+content fetch for AI summary)"
  MAX_CHARS = 12_000
  MIN_CHARS = 40
  STRIP_SELECTOR = "script, style, nav, header, footer, noscript, svg".freeze

  def self.call(url, url_type) = new(url, url_type).call

  def initialize(url, url_type)
    @url = url
    @url_type = url_type
  end

  def call
    response = http_get(URI(@url))
    return nil unless response.is_a?(Net::HTTPSuccess)

    text = @url_type == "youtube" ? extract_youtube_description(response.body) : extract_page_text(response.body)
    text = text.to_s.strip
    text.length >= MIN_CHARS ? text.truncate(MAX_CHARS, omission: "") : nil
  rescue StandardError => e
    Rails.logger.warn("[BookmarkContentFetcher] #{@url} failed: #{e.class} #{e.message}")
    nil
  end

  private
    def extract_page_text(html)
      doc = Nokogiri::HTML(html)
      doc.css(STRIP_SELECTOR).remove
      (doc.at_css("body") || doc).text.gsub(/[ \t]+/, " ").gsub(/\n{2,}/, "\n").strip
    end

    def extract_youtube_description(html)
      doc = Nokogiri::HTML(html)
      meta = doc.at_css('meta[property="og:description"]') || doc.at_css('meta[name="description"]')
      meta && meta["content"]
    end

    def http_get(uri)
      Net::HTTP.start(uri.host, uri.port,
                       use_ssl: uri.scheme == "https",
                       open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.get(uri.request_uri.presence || "/", { "User-Agent" => USER_AGENT })
      end
    end
end
