require "test_helper"

class AiSummarizerTest < ActiveSupport::TestCase
  URL = "https://generativelanguage.googleapis.com/v1beta/models/#{AiSummarizer::MODEL}:generateContent".freeze

  setup do
    @previous_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = "test-key-123"
  end

  teardown do
    ENV["GEMINI_API_KEY"] = @previous_key
  end

  test "returns the summary text from a successful response" do
    stub_request(:post, URL).to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        candidates: [
          {
            content: { role: "model", parts: [ { text: "Ruby is a dynamic programming language." } ] },
            finishReason: "STOP"
          }
        ]
      }.to_json
    )

    result = AiSummarizer.call(title: "Ruby", content: "Ruby is a dynamic, open source language.")

    assert_equal "Ruby is a dynamic programming language.", result
    assert_requested :post, URL do |req|
      req.headers["X-Goog-Api-Key"] == "test-key-123" &&
        JSON.parse(req.body).dig("contents", 0, "parts", 0, "text").include?("Ruby is a dynamic, open source language.")
    end
  end

  test "returns nil without making a request when GEMINI_API_KEY is blank" do
    ENV["GEMINI_API_KEY"] = nil

    assert_nil AiSummarizer.call(title: "Ruby", content: "Some content")
    assert_not_requested :post, URL
  end

  test "returns nil on an authentication error" do
    stub_request(:post, URL).to_return(
      status: 401,
      headers: { "Content-Type" => "application/json" },
      body: { error: { code: 401, message: "API key not valid", status: "UNAUTHENTICATED" } }.to_json
    )

    assert_nil AiSummarizer.call(title: "Ruby", content: "Some content")
  end

  test "returns nil on a rate limit error" do
    stub_request(:post, URL).to_return(
      status: 429,
      headers: { "Content-Type" => "application/json" },
      body: { error: { code: 429, message: "Resource has been exhausted", status: "RESOURCE_EXHAUSTED" } }.to_json
    )

    assert_nil AiSummarizer.call(title: "Ruby", content: "Some content")
  end

  test "returns nil when the response has no candidate text" do
    stub_request(:post, URL).to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: { candidates: [ { finishReason: "SAFETY" } ] }.to_json
    )

    assert_nil AiSummarizer.call(title: "Ruby", content: "Some content")
  end

  test "returns nil on a timeout" do
    stub_request(:post, URL).to_timeout

    assert_nil AiSummarizer.call(title: "Ruby", content: "Some content")
  end
end
