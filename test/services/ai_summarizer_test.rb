require "test_helper"

class AiSummarizerTest < ActiveSupport::TestCase
  setup do
    @previous_key = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "test-key-123"
  end

  teardown do
    ENV["ANTHROPIC_API_KEY"] = @previous_key
  end

  test "returns the summary text from a successful response" do
    stub_request(:post, "https://api.anthropic.com/v1/messages").to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        id: "msg_123", type: "message", role: "assistant",
        content: [ { type: "text", text: "Ruby is a dynamic programming language." } ],
        model: "claude-haiku-4-5", stop_reason: "end_turn", stop_sequence: nil,
        usage: { input_tokens: 50, output_tokens: 10 }
      }.to_json
    )

    result = AiSummarizer.call(title: "Ruby", content: "Ruby is a dynamic, open source language.")

    assert_equal "Ruby is a dynamic programming language.", result
  end

  test "returns nil without making a request when ANTHROPIC_API_KEY is blank" do
    ENV["ANTHROPIC_API_KEY"] = nil

    assert_nil AiSummarizer.call(title: "Ruby", content: "Some content")
    assert_not_requested :post, "https://api.anthropic.com/v1/messages"
  end

  test "returns nil on an authentication error" do
    stub_request(:post, "https://api.anthropic.com/v1/messages").to_return(
      status: 401,
      headers: { "Content-Type" => "application/json" },
      body: { type: "error", error: { type: "authentication_error", message: "invalid key" } }.to_json
    )

    assert_nil AiSummarizer.call(title: "Ruby", content: "Some content")
  end

  test "returns nil on a rate limit error" do
    stub_request(:post, "https://api.anthropic.com/v1/messages").to_return(
      status: 429,
      headers: { "Content-Type" => "application/json" },
      body: { type: "error", error: { type: "rate_limit_error", message: "slow down" } }.to_json
    )

    assert_nil AiSummarizer.call(title: "Ruby", content: "Some content")
  end

  test "returns nil on a timeout" do
    stub_request(:post, "https://api.anthropic.com/v1/messages").to_timeout

    assert_nil AiSummarizer.call(title: "Ruby", content: "Some content")
  end
end
