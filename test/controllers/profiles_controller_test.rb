require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post login_path, params: { email: @user.email, password: "password" }
  end

  test "GET /profile renders the details page" do
    get profile_path
    assert_response :success
  end

  test "PATCH /profile/name updates the name and redirects" do
    patch "/profile/name", params: { name: "New Name" }

    assert_redirected_to profile_path
    assert_equal "New Name", @user.reload.name
  end

  test "PATCH /profile/name strips surrounding whitespace" do
    patch "/profile/name", params: { name: "  Spaced Out  " }

    assert_redirected_to profile_path
    assert_equal "Spaced Out", @user.reload.name
  end

  test "PATCH /profile/name allows a blank name" do
    patch "/profile/name", params: { name: "" }

    assert_redirected_to profile_path
    assert_equal "", @user.reload.name.to_s
  end

  test "PATCH /profile/name rejects a name longer than 100 characters" do
    original = @user.name
    patch "/profile/name", params: { name: "a" * 101 }

    assert_response :redirect
    assert_equal original, @user.reload.name
  end

  test "unauthenticated users cannot update the name" do
    delete logout_path
    patch "/profile/name", params: { name: "Nope" }

    assert_redirected_to login_path
  end
end
