# Fetches a bookmark's content and generates an AI summary in the background.
# Always resolves the bookmark to a terminal summary_status (completed or
# failed) rather than raising, so Solid Queue never needs to retry this job.
class BookmarkSummarizationJob < ApplicationJob
  queue_as :default

  def perform(bookmark_id)
    bookmark = Bookmark.find_by(id: bookmark_id)
    return unless bookmark

    content = BookmarkContentFetcher.call(bookmark.url, bookmark.url_type)
    if content.blank?
      bookmark.update!(summary_status: :failed)
      return
    end

    summary = AiSummarizer.call(title: bookmark.title, content: content)
    if summary.blank?
      bookmark.update!(summary_status: :failed)
    else
      bookmark.update!(summary: summary, summary_status: :completed)
    end
  end
end
