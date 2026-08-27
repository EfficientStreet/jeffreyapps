require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @ruby = tags(:ruby)
    @rails = tags(:rails)
    @other_tag = tags(:user_two_tag)
    @password = "password"
  end

  test "unauthenticated users are redirected to login" do
    get tags_path
    assert_redirected_to login_path

    patch tag_path(@ruby), params: { tag: { name: "New" } }
    assert_redirected_to login_path

    delete tag_path(@ruby)
    assert_redirected_to login_path

    post merge_tag_path(@ruby), params: { target_tag_id: @rails.id }
    assert_redirected_to login_path
  end

  test "index lists only the current user's tags" do
    log_in_as(@user)
    get tags_path
    assert_response :success
  end

  test "update renames a tag" do
    log_in_as(@user)
    patch tag_path(@ruby), params: { tag: { name: "Ruby Lang" } }
    assert_redirected_to tags_path
    assert_equal "Ruby Lang", @ruby.reload.name
  end

  test "update rejects a case-insensitive duplicate name" do
    log_in_as(@user)
    patch tag_path(@ruby), params: { tag: { name: "rails" } }
    assert_response :redirect
    assert_equal "Ruby", @ruby.reload.name
  end

  test "update on another user's tag 404s" do
    log_in_as(@user)
    patch tag_path(@other_tag), params: { tag: { name: "Hijacked" } }
    assert_response :not_found
  end

  test "destroy removes the tag and its bookmark_tags without touching bookmarks" do
    log_in_as(@user)
    bookmark = bookmarks(:rails_guides)
    assert_difference("Tag.count", -1) do
      assert_difference("BookmarkTag.count", -1) { delete tag_path(@ruby) }
    end
    assert Bookmark.exists?(bookmark.id)
  end

  test "destroy on another user's tag 404s" do
    log_in_as(@user)
    delete tag_path(@other_tag)
    assert_response :not_found
  end

  test "merge moves bookmark_tags to the target and destroys the source" do
    log_in_as(@user)
    post merge_tag_path(@ruby), params: { target_tag_id: @rails.id }

    assert_redirected_to tags_path
    assert_not Tag.exists?(@ruby.id)
    assert_includes bookmarks(:rails_guides).reload.tags, @rails
  end

  test "merge dedups a bookmark already tagged with both source and target" do
    log_in_as(@user)
    shared_bookmark = bookmarks(:rails_guides) # already tagged with both ruby and rails

    post merge_tag_path(@ruby), params: { target_tag_id: @rails.id }

    assert_redirected_to tags_path
    assert_equal [ @rails.id ], shared_bookmark.reload.tags.pluck(:id)
  end

  test "merge rejects merging a tag into itself" do
    log_in_as(@user)
    post merge_tag_path(@ruby), params: { target_tag_id: @ruby.id }

    assert Tag.exists?(@ruby.id)
  end

  test "merge rejects a target_tag_id belonging to another user" do
    log_in_as(@user)
    post merge_tag_path(@ruby), params: { target_tag_id: @other_tag.id }

    assert Tag.exists?(@ruby.id)
  end

  private
    def log_in_as(user)
      post login_path, params: { email: user.email, password: @password }
    end
end
