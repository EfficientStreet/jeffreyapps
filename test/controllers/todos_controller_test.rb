require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "requires authentication" do
    get todos_path
    assert_redirected_to login_path
  end

  test "renders the To-Dos page when signed in" do
    post login_path, params: { email: @user.email, password: "password" }
    get todos_path
    assert_response :success
  end
end
