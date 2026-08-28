require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "valid with a url and title" do
    bookmark = Bookmark.new(user: @user, url: "https://example.com", title: "Example")
    assert bookmark.valid?
  end

  test "invalid without a url" do
    bookmark = Bookmark.new(user: @user, title: "Example")
    assert_not bookmark.valid?
    assert_includes bookmark.errors[:url], "can't be blank"
  end

  test "invalid without a title" do
    bookmark = Bookmark.new(user: @user, url: "https://example.com")
    assert_not bookmark.valid?
    assert_includes bookmark.errors[:title], "can't be blank"
  end

  test "rejects javascript: scheme urls" do
    bookmark = Bookmark.new(user: @user, url: "javascript:alert(1)", title: "Bad")
    assert_not bookmark.valid?
    assert_includes bookmark.errors[:url], "must be a valid http:// or https:// address"
  end

  test "rejects malformed urls" do
    bookmark = Bookmark.new(user: @user, url: "not a url", title: "Bad")
    assert_not bookmark.valid?
    assert_includes bookmark.errors[:url], "must be a valid http:// or https:// address"
  end

  test "accepts http and https urls" do
    assert Bookmark.new(user: @user, url: "http://example.com", title: "Example").url_valid_format?
    assert Bookmark.new(user: @user, url: "https://example.com", title: "Example").url_valid_format?
  end

  test "url_type must be a valid enum value" do
    bookmark = Bookmark.new(user: @user, url: "https://example.com", title: "Example")
    bookmark.url_type = "carrier_pigeon"
    assert_not bookmark.valid?
    assert_includes bookmark.errors[:url_type], "is not included in the list"
  end

  test "summary_status defaults to pending" do
    bookmark = Bookmark.create!(user: @user, url: "https://example.com", title: "Example")
    assert bookmark.pending?
  end

  test "summary_status must be a valid enum value" do
    bookmark = Bookmark.new(user: @user, url: "https://example.com", title: "Example")
    bookmark.summary_status = "in_orbit"
    assert_not bookmark.valid?
    assert_includes bookmark.errors[:summary_status], "is not included in the list"
  end

  test ".detect_url_type recognizes youtube hosts" do
    %w[
      https://youtube.com/watch?v=abc
      https://www.youtube.com/watch?v=abc
      https://m.youtube.com/watch?v=abc
      https://youtu.be/abc
    ].each do |url|
      assert_equal "youtube", Bookmark.detect_url_type(url), "expected #{url} to be youtube"
    end
  end

  test ".detect_url_type falls back to website for everything else" do
    assert_equal "website", Bookmark.detect_url_type("https://example.com")
    assert_equal "website", Bookmark.detect_url_type("not a url")
  end

  test "belongs to a user" do
    assert_equal @user, bookmarks(:rails_guides).user
  end

  test "destroying a bookmark destroys its bookmark_tags but not its tags" do
    bookmark = bookmarks(:rails_guides)
    tag = tags(:ruby)
    assert_difference("BookmarkTag.count", -2) do
      bookmark.destroy
    end
    assert Tag.exists?(tag.id)
  end
end
