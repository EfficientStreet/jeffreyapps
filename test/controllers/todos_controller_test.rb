require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @password = "password" # matches test/fixtures/users.yml
    @todo = todos(:one_incomplete)
    @other_todo = todos(:two_incomplete)
  end

  test "unauthenticated users cannot view the todo list" do
    get todos_path
    assert_redirected_to login_path
  end

  test "authenticated users can view the todo list" do
    log_in_as(@user)
    get todos_path
    assert_response :success
  end

  test "unauthenticated users cannot create a todo" do
    assert_no_difference -> { Todo.count } do
      post todos_path, params: { description: "New task" }
    end
    assert_redirected_to login_path
  end

  test "creates a todo for the current user" do
    log_in_as(@user)

    assert_difference -> { @user.todos.count }, 1 do
      post todos_path, params: { description: "New task" }
    end

    assert_redirected_to todos_path
    assert_equal "New task", @user.todos.order(:created_at).last.description
  end

  test "does not create a todo with a blank description" do
    log_in_as(@user)

    assert_no_difference -> { Todo.count } do
      post todos_path, params: { description: "" }
    end

    assert_redirected_to todos_path
  end

  test "toggles a todo from incomplete to complete" do
    log_in_as(@user)

    patch todo_path(@todo), params: { completed: true }

    assert_redirected_to todos_path
    assert @todo.reload.completed?
  end

  test "toggles a todo from complete to incomplete" do
    log_in_as(@user)
    completed_todo = todos(:one_completed)

    patch todo_path(completed_todo), params: { completed: false }

    assert_redirected_to todos_path
    assert_not completed_todo.reload.completed?
  end

  test "edits a todo's description" do
    log_in_as(@user)

    patch todo_path(@todo), params: { description: "Buy oat milk" }

    assert_redirected_to todos_path
    assert_equal "Buy oat milk", @todo.reload.description
  end

  test "cannot update another user's todo" do
    log_in_as(@user)

    patch todo_path(@other_todo), params: { completed: true }

    assert_response :not_found
    assert_not @other_todo.reload.completed?
  end

  test "destroys a todo" do
    log_in_as(@user)

    assert_difference -> { Todo.count }, -1 do
      delete todo_path(@todo)
    end

    assert_redirected_to todos_path
  end

  test "cannot destroy another user's todo" do
    log_in_as(@user)

    assert_no_difference -> { Todo.count } do
      delete todo_path(@other_todo)
    end

    assert_response :not_found
  end

  private
    def log_in_as(user)
      post login_path, params: { email: user.email, password: @password }
    end
end
