require "test_helper"

class BookmarkContentFetcherTest < ActiveSupport::TestCase
  test "extracts visible body text from a website, stripping script/style/nav" do
    html = <<~HTML
      <html>
        <head><style>body { color: red; }</style></head>
        <body>
          <nav>Site nav</nav>
          <script>console.log("hi")</script>
          <main>#{"Ruby is a dynamic, open source programming language. " * 3}</main>
          <footer>Copyright</footer>
        </body>
      </html>
    HTML
    stub_request(:get, "https://example.com/").to_return(status: 200, body: html)

    result = BookmarkContentFetcher.call("https://example.com", "website")

    assert_includes result, "Ruby is a dynamic"
    assert_not_includes result, "Site nav"
    assert_not_includes result, "console.log"
    assert_not_includes result, "Copyright"
  end

  test "extracts the og:description meta tag for a YouTube url" do
    html = <<~HTML
      <html><head>
        <meta property="og:description" content="#{"A talk about Ruby internals. " * 3}">
      </head></html>
    HTML
    stub_request(:get, "https://www.youtube.com/watch?v=abc").to_return(status: 200, body: html)

    result = BookmarkContentFetcher.call("https://www.youtube.com/watch?v=abc", "youtube")

    assert_includes result, "A talk about Ruby internals."
  end

  test "falls back to the name=description meta tag when og:description is absent" do
    html = <<~HTML
      <html><head>
        <meta name="description" content="#{"Backup description text here. " * 3}">
      </head></html>
    HTML
    stub_request(:get, "https://www.youtube.com/watch?v=abc").to_return(status: 200, body: html)

    result = BookmarkContentFetcher.call("https://www.youtube.com/watch?v=abc", "youtube")

    assert_includes result, "Backup description text here."
  end

  test "returns nil on a timeout" do
    stub_request(:get, "https://slow.example.com/").to_timeout

    assert_nil BookmarkContentFetcher.call("https://slow.example.com", "website")
  end

  test "returns nil on a non-2xx response" do
    stub_request(:get, "https://broken.example.com/").to_return(status: 404)

    assert_nil BookmarkContentFetcher.call("https://broken.example.com", "website")
  end

  test "returns nil when extracted content is too short to summarize" do
    stub_request(:get, "https://thin.example.com/").to_return(
      status: 200, body: "<html><body>hi</body></html>"
    )

    assert_nil BookmarkContentFetcher.call("https://thin.example.com", "website")
  end

  test "truncates content longer than MAX_CHARS" do
    long_text = "word " * 5000
    stub_request(:get, "https://long.example.com/").to_return(
      status: 200, body: "<html><body>#{long_text}</body></html>"
    )

    result = BookmarkContentFetcher.call("https://long.example.com", "website")

    assert_equal BookmarkContentFetcher::MAX_CHARS, result.length
  end
end
