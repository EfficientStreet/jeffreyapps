require "application_system_test_case"

class TodosTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    # Fixtures seed this user with todos (one also named "Buy milk"); clear them
    # so the single "Buy milk" this test creates is unambiguous.
    @user.todos.destroy_all
  end

  test "creating, completing, editing, and deleting a todo" do
    visit login_path
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password"
    click_button "Log in"

    # Wait for the async Inertia login POST to land before navigating.
    assert_selector "h1", text: "Dashboard"

    click_link "To-Doer"
    assert_selector "h1", text: "Jamie One’s To-Dos"

    # The nav click is an Inertia client-side visit; the page's JS chunk hydrates
    # a beat after its (server-rendered) HTML appears. Reload so we interact with
    # a fully-hydrated page and the controlled add-box input keeps what we type.
    refresh
    assert_selector "h1", text: "Jamie One’s To-Dos"

    add_todo "Buy milk"

    within("section", text: "To-Dos") do
      assert_selector "li", text: "Buy milk"
    end

    within("li", text: "Buy milk") do
      find("input[type='checkbox']").click
    end

    within("section", text: "Completed") do
      assert_selector "li button.line-through", text: "Buy milk"
    end

    within("li", text: "Buy milk") do
      click_button "Buy milk"
      field = find("input[aria-label='Edit to-do description']")
      field.set("Buy oat milk")
      field.send_keys(:enter)
    end

    within("section", text: "Completed") do
      assert_selector "li button.line-through", text: "Buy oat milk"
    end

    within("li", text: "Buy oat milk") do
      find("button[aria-label='Delete to-do']").click
    end

    # Positive wait for the empty state before asserting the row is gone.
    assert_text "Nothing to do. Add a to-do above."
    assert_no_selector "li", text: "Buy oat milk"

    # App shell footer
    within("footer") do
      assert_link "Bug Reports / Feature Requests / Feedback"
      assert_link "JeffreyApps.com", href: "mailto:jeffrey@efficientstreet.com"
      assert_selector "a[aria-label='LinkedIn']"
    end
  end

  private
    # The add box is a controlled React input that drops keystrokes typed before
    # hydration finishes; see ApplicationSystemTestCase#fill_in_hydrated.
    def add_todo(description)
      fill_in_hydrated "todo-description", with: description
      click_button "Add"
    end
end
