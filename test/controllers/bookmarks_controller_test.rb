require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "requires authentication" do
    get bookmarks_path
    assert_redirected_to login_path
  end

  test "renders the Bookmarks page when signed in" do
    post login_path, params: { email: @user.email, password: "password" }
    get bookmarks_path
    assert_response :success
  end
end
