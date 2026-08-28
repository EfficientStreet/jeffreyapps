require "test_helper"

class BookmarkSummarizationJobTest < ActiveJob::TestCase
  setup do
    @bookmark = bookmarks(:rails_guides)
    @bookmark.update!(summary_status: :pending)
  end

  test "marks the bookmark completed with the generated summary on success" do
    BookmarkContentFetcher.stub :call, "some fetched content" do
      AiSummarizer.stub :call, "A concise summary." do
        BookmarkSummarizationJob.perform_now(@bookmark.id)
      end
    end

    @bookmark.reload
    assert @bookmark.completed?
    assert_equal "A concise summary.", @bookmark.summary
  end

  test "marks the bookmark failed when content fetching yields nothing" do
    BookmarkContentFetcher.stub :call, nil do
      BookmarkSummarizationJob.perform_now(@bookmark.id)
    end

    assert @bookmark.reload.failed?
  end

  test "marks the bookmark failed when the summarizer yields nothing" do
    BookmarkContentFetcher.stub :call, "some fetched content" do
      AiSummarizer.stub :call, nil do
        BookmarkSummarizationJob.perform_now(@bookmark.id)
      end
    end

    assert @bookmark.reload.failed?
  end

  test "is a no-op when the bookmark no longer exists" do
    deleted_id = @bookmark.id
    @bookmark.destroy

    assert_nothing_raised { BookmarkSummarizationJob.perform_now(deleted_id) }
  end
end
