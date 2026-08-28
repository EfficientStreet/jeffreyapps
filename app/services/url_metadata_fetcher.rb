# Synchronously fetches a bookmarked URL's title (and confirms its type) when
# a bookmark is created. Never raises and never blocks a save: any network
# failure, timeout, or unparseable response falls back to the URL's host as
# the title.
class UrlMetadataFetcher
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 5
  USER_AGENT = "JeffreyAppsBot/1.0 (+synchronous metadata fetch)"

  Result = Struct.new(:title, :url_type, keyword_init: true)

  def self.call(url) = new(url).call

  def initialize(url)
    @url = url
  end

  def call
    url_type = Bookmark.detect_url_type(@url)
    # oEmbed only covers actual video/playlist URLs -- it has no provider
    # for channel pages (e.g. youtube.com/@handle), so those 400 and fall
    # through to scraping the page's own <title> tag, same as a website.
    title = url_type == "youtube" ? fetch_youtube_title.presence || fetch_html_title : fetch_html_title
    Result.new(title: title.presence || fallback_title, url_type: url_type)
  rescue StandardError => e
    Rails.logger.warn("[UrlMetadataFetcher] #{@url} failed: #{e.class} #{e.message}")
    Result.new(title: fallback_title, url_type: Bookmark.detect_url_type(@url))
  end

  private
    def fetch_youtube_title
      uri = URI("https://www.youtube.com/oembed?url=#{ERB::Util.url_encode(@url)}&format=json")
      response = http_get(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)["title"]
    rescue StandardError
      nil
    end

    def fetch_html_title
      uri = URI(@url)
      response = http_get(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)
      Nokogiri::HTML(response.body).at_css("title")&.text&.strip
    rescue StandardError
      nil
    end

    def http_get(uri)
      Net::HTTP.start(uri.host, uri.port,
                       use_ssl: uri.scheme == "https",
                       open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        http.get(uri.request_uri.presence || "/", { "User-Agent" => USER_AGENT })
      end
    end

    def fallback_title
      URI.parse(@url.to_s).host.presence || @url.to_s
    rescue URI::InvalidURIError
      @url.to_s
    end
end
