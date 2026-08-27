require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @bookmark = bookmarks(:rails_guides)
    @other_bookmark = bookmarks(:user_two_bookmark)
    @password = "password"
  end

  test "unauthenticated users are redirected to login" do
    get bookmarks_path
    assert_redirected_to login_path

    get bookmark_path(@bookmark)
    assert_redirected_to login_path

    post bookmarks_path, params: { bookmark: { url: "https://example.com" } }
    assert_redirected_to login_path

    patch bookmark_path(@bookmark), params: { bookmark: { title: "New" } }
    assert_redirected_to login_path

    delete bookmark_path(@bookmark)
    assert_redirected_to login_path
  end

  test "index lists only the current user's bookmarks" do
    log_in_as(@user)
    get bookmarks_path
    assert_response :success
  end

  test "show returns 404 for another user's bookmark" do
    log_in_as(@user)
    get bookmark_path(@other_bookmark)
    assert_response :not_found
  end

  test "create saves a bookmark using the fetched title and type" do
    log_in_as(@user)
    result = UrlMetadataFetcher::Result.new(title: "Fetched Title", url_type: "website")

    assert_difference("Bookmark.count", 1) do
      UrlMetadataFetcher.stub :call, result do
        post bookmarks_path, params: { bookmark: { url: "https://example.org", notes: "hi" } }
      end
    end

    assert_redirected_to bookmarks_path
    bookmark = Bookmark.last
    assert_equal "Fetched Title", bookmark.title
    assert_equal "website", bookmark.url_type
    assert_equal @user, bookmark.user
  end

  # Milestone-3 title reconciliation: the PRD says title is "auto-filled from the
  # page if blank", so a user-provided title must NOT be overwritten by the
  # fetched one (bookmarker always overwrote it).
  test "create keeps a user-provided title instead of the fetched one" do
    log_in_as(@user)
    result = UrlMetadataFetcher::Result.new(title: "Fetched Title", url_type: "website")

    assert_difference("Bookmark.count", 1) do
      UrlMetadataFetcher.stub :call, result do
        post bookmarks_path, params: { bookmark: { url: "https://example.org", title: "My Own Title" } }
      end
    end

    bookmark = Bookmark.last
    assert_equal "My Own Title", bookmark.title
    assert_equal "website", bookmark.url_type
  end

  test "create rejects an invalid url without saving" do
    log_in_as(@user)
    assert_no_difference("Bookmark.count") do
      post bookmarks_path, params: { bookmark: { url: "javascript:alert(1)" } }
    end
    assert_response :redirect
  end

  test "create syncs tags, reusing an existing tag case-insensitively" do
    log_in_as(@user)
    result = UrlMetadataFetcher::Result.new(title: "Fetched Title", url_type: "website")

    assert_difference("Tag.count", 1) do
      UrlMetadataFetcher.stub :call, result do
        post bookmarks_path, params: { bookmark: { url: "https://example.org", tag_names: [ "RUBY", "brand-new" ] } }
      end
    end

    bookmark = Bookmark.last
    assert_equal [ "Ruby", "brand-new" ], bookmark.tags.pluck(:name).sort
  end

  test "update changes title and notes without touching tags when tag_names is absent" do
    log_in_as(@user)
    patch bookmark_path(@bookmark), params: { bookmark: { title: "Updated title", notes: "Updated notes" } }

    assert_redirected_to bookmark_path(@bookmark)
    @bookmark.reload
    assert_equal "Updated title", @bookmark.title
    assert_equal "Updated notes", @bookmark.notes
    assert_equal 2, @bookmark.tags.count
  end

  test "update with only tag_names does not clobber the title" do
    log_in_as(@user)
    patch bookmark_path(@bookmark), params: { bookmark: { tag_names: [ "solo" ] } }

    @bookmark.reload
    assert_equal "Ruby on Rails Guides", @bookmark.title
    assert_equal [ "solo" ], @bookmark.tags.pluck(:name)
  end

  test "update on another user's bookmark 404s" do
    log_in_as(@user)
    patch bookmark_path(@other_bookmark), params: { bookmark: { title: "Nope" } }
    assert_response :not_found
  end

  test "destroy removes the bookmark and its bookmark_tags" do
    log_in_as(@user)
    assert_difference("Bookmark.count", -1) do
      assert_difference("BookmarkTag.count", -2) { delete bookmark_path(@bookmark) }
    end
    assert_redirected_to bookmarks_path
  end

  test "destroy on another user's bookmark 404s" do
    log_in_as(@user)
    delete bookmark_path(@other_bookmark)
    assert_response :not_found
  end

  private
    def log_in_as(user)
      post login_path, params: { email: user.email, password: @password }
    end
end
