require "net/http"
require "json"

# Generates a short summary of a bookmark's fetched content using the Google
# Gemini API. Never raises: a missing API key, network failure, non-2xx
# response, or unexpected error is logged and results in a nil return, which
# BookmarkSummarizationJob treats as a failed summarization attempt (not a
# crashed job).
class AiSummarizer
  MODEL = ENV.fetch("GEMINI_MODEL", "gemini-2.5-flash")
  MAX_OUTPUT_TOKENS = 1024
  TEMPERATURE = 0.3
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 20
  ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models".freeze

  SYSTEM_PROMPT = <<~PROMPT.strip
    You summarize bookmarked web pages and videos for a personal bookmarking app.
    Write a neutral, factual summary in 2-4 sentences based only on the provided
    title and content. Do not add commentary, opinions, or information not
    present in the content. Respond with the summary text only — no preamble,
    no headings, no quotation marks.
  PROMPT

  def self.call(title:, content:) = new(title: title, content: content).call

  def initialize(title:, content:)
    @title = title
    @content = content
  end

  def call
    api_key = ENV["GEMINI_API_KEY"]
    return nil if api_key.blank?

    response = post(api_key)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[AiSummarizer] Gemini API error: #{response.code} #{response.body.to_s.truncate(300)}")
      return nil
    end

    json = JSON.parse(response.body)
    text = json.dig("candidates", 0, "content", "parts", 0, "text")
    text.presence&.strip
  rescue StandardError => e
    Rails.logger.warn("[AiSummarizer] unexpected error: #{e.class} #{e.message}")
    nil
  end

  private
    # Single attempt, fail fast: this runs from a background job with no user
    # waiting on the response, so there's no benefit to retrying — let the job
    # simply mark the summary as failed.
    def post(api_key)
      uri = URI("#{ENDPOINT}/#{MODEL}:generateContent")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["x-goog-api-key"] = api_key
      request.body = request_body

      http.request(request)
    end

    def request_body
      {
        systemInstruction: { parts: [ { text: SYSTEM_PROMPT } ] },
        contents: [ { role: "user", parts: [ { text: "Title: #{@title}\n\nContent:\n#{@content}" } ] } ],
        generationConfig: { temperature: TEMPERATURE, maxOutputTokens: MAX_OUTPUT_TOKENS }
      }.to_json
    end
end
