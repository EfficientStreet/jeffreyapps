require "test_helper"

class TodoTest < ActiveSupport::TestCase
  setup do
    @todo = todos(:one_incomplete)
  end

  test "valid with a description" do
    assert @todo.valid?
  end

  test "invalid without a description" do
    @todo.description = ""
    assert_not @todo.valid?
    assert_includes @todo.errors[:description], "can't be blank"
  end

  test "invalid with a description over 500 characters" do
    @todo.description = "a" * 501
    assert_not @todo.valid?
  end

  test "invalid without a user" do
    @todo.user = nil
    assert_not @todo.valid?
  end

  test "ordered lists incomplete todos before completed ones" do
    ordered = Todo.where(user: users(:one)).ordered
    assert_equal [ todos(:one_incomplete), todos(:one_completed) ], ordered.to_a
  end

  test "destroying a user destroys their todos" do
    user = users(:one)
    assert_difference -> { Todo.count }, -user.todos.count do
      user.destroy
    end
  end
end
