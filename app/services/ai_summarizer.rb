# Generates a short summary of a bookmark's fetched content using Claude.
# Never raises: any missing API key, network failure, or API error is logged
# and results in a nil return, which BookmarkSummarizationJob treats as a
# failed summarization attempt (not a crashed job).
class AiSummarizer
  MODEL = "claude-haiku-4-5"
  MAX_TOKENS = 1024
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
    return nil if ENV["ANTHROPIC_API_KEY"].blank?

    response = client.messages.create(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      temperature: 0.3,
      system: SYSTEM_PROMPT,
      messages: [ { role: "user", content: "Title: #{@title}\n\nContent:\n#{@content}" } ]
    )
    text = response.content.find { |block| block.type == :text }&.text
    text.presence&.strip
  rescue Anthropic::Errors::RateLimitError, Anthropic::Errors::APIStatusError,
         Anthropic::Errors::APIConnectionError => e
    Rails.logger.warn("[AiSummarizer] API error: #{e.class} #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.warn("[AiSummarizer] unexpected error: #{e.class} #{e.message}")
    nil
  end

  private
    # max_retries: 0 — this runs from a background job with no user waiting
    # on the response, so there's no benefit to the SDK's default backoff
    # retries; fail fast and let the job simply mark the summary as failed.
    def client = @client ||= Anthropic::Client.new(max_retries: 0)
end
