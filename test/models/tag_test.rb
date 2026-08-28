require "test_helper"

class TagTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "valid with a name" do
    assert Tag.new(user: @user, name: "Cooking").valid?
  end

  test "invalid without a name" do
    tag = Tag.new(user: @user, name: "")
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "rejects a case-insensitive duplicate name for the same user" do
    tag = Tag.new(user: @user, name: "ruby")
    assert_not tag.valid?
    assert_includes tag.errors[:name], "has already been taken"
  end

  test "allows the same name for different users" do
    tag = Tag.new(user: users(:two), name: "Ruby")
    assert tag.valid?
  end

  test "strips whitespace from the name" do
    tag = Tag.create!(user: @user, name: "  Cooking  ")
    assert_equal "Cooking", tag.name
  end

  test "destroying a tag destroys its bookmark_tags but leaves bookmarks intact" do
    tag = tags(:ruby)
    bookmark = bookmarks(:rails_guides)
    assert_difference("BookmarkTag.count", -1) do
      tag.destroy
    end
    assert Bookmark.exists?(bookmark.id)
  end
end
