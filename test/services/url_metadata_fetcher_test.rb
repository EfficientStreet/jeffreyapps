require "test_helper"

class UrlMetadataFetcherTest < ActiveSupport::TestCase
  test "extracts the <title> from a fetched HTML page" do
    stub_request(:get, "https://example.com/").to_return(
      status: 200, body: "<html><head><title>  Example Domain  </title></head></html>"
    )

    result = UrlMetadataFetcher.call("https://example.com")

    assert_equal "Example Domain", result.title
    assert_equal "website", result.url_type
  end

  test "uses YouTube's oEmbed title for a YouTube url" do
    stub_request(:get, /youtube\.com\/oembed/).to_return(
      status: 200, body: { title: "A great talk" }.to_json
    )

    result = UrlMetadataFetcher.call("https://www.youtube.com/watch?v=dQw4w9WgXcQ")

    assert_equal "A great talk", result.title
    assert_equal "youtube", result.url_type
  end

  test "falls back to scraping the page <title> when oEmbed has no provider (e.g. a channel URL)" do
    stub_request(:get, /youtube\.com\/oembed/).to_return(status: 400)
    stub_request(:get, "https://www.youtube.com/@SomeCreator").to_return(
      status: 200, body: "<html><head><title>SomeCreator - YouTube</title></head></html>"
    )

    result = UrlMetadataFetcher.call("https://www.youtube.com/@SomeCreator")

    assert_equal "SomeCreator - YouTube", result.title
    assert_equal "youtube", result.url_type
  end

  test "falls back to the host on a timeout" do
    stub_request(:get, "https://slow.example.com/").to_timeout

    result = UrlMetadataFetcher.call("https://slow.example.com")

    assert_equal "slow.example.com", result.title
    assert_equal "website", result.url_type
  end

  test "falls back to the host on a non-2xx response" do
    stub_request(:get, "https://broken.example.com/").to_return(status: 404)

    result = UrlMetadataFetcher.call("https://broken.example.com")

    assert_equal "broken.example.com", result.title
  end

  test "falls back to the host on malformed HTML with no title" do
    stub_request(:get, "https://notitle.example.com/").to_return(status: 200, body: "<html><body>hi</body></html>")

    result = UrlMetadataFetcher.call("https://notitle.example.com")

    assert_equal "notitle.example.com", result.title
  end
end
