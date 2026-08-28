require "test_helper"

class BookmarkTagTest < ActiveSupport::TestCase
  test "rejects a duplicate bookmark/tag pair" do
    duplicate = BookmarkTag.new(bookmark: bookmarks(:rails_guides), tag: tags(:ruby))
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tag_id], "has already been taken"
  end

  test "rejects pairing a bookmark with another user's tag" do
    cross_user = BookmarkTag.new(bookmark: bookmarks(:rails_guides), tag: tags(:user_two_tag))
    assert_not cross_user.valid?
    assert_includes cross_user.errors[:tag], "must belong to the same user as the bookmark"
  end
end
