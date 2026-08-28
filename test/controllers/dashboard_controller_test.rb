require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @password = "password"
  end

  test "unauthenticated users are redirected to login" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "authenticated users can view the dashboard" do
    log_in_as(@user)
    get dashboard_path
    assert_response :success
  end

  test "open to-dos snapshot counts only the current user's incomplete todos" do
    @user.todos.destroy_all
    @user.todos.create!(description: "Open one", completed: false)
    @user.todos.create!(description: "Open two", completed: false)
    @user.todos.create!(description: "Done", completed: true)
    @other_user.todos.create!(description: "Someone else's open todo", completed: false)

    props = inertia_props_for(dashboard_path)

    assert_equal 2, props["open_todos_count"]
    assert_equal [ "Open one", "Open two" ], props["open_todos"].map { |t| t["description"] }
  end

  test "recent bookmarks snapshot returns the current user's five newest, newest first" do
    @user.bookmarks.destroy_all
    6.times do |i|
      @user.bookmarks.create!(url: "https://example.com/#{i}", title: "Bookmark #{i}", created_at: i.minutes.ago)
    end
    @other_user.bookmarks.create!(url: "https://example.com/other", title: "Other user bookmark")

    props = inertia_props_for(dashboard_path)
    titles = props["recent_bookmarks"].map { |b| b["title"] }

    assert_equal 5, titles.length
    assert_equal "Bookmark 0", titles.first
    assert_not_includes titles, "Bookmark 5"
    assert_not_includes titles, "Other user bookmark"
  end

  private
    def log_in_as(user)
      post login_path, params: { email: user.email, password: @password }
    end

    # Pull the Inertia page object out of the rendered document's
    # `<div id="app" data-page="...">` and return its props hash.
    def inertia_props_for(path)
      log_in_as(@user)
      get path
      assert_response :success
      page_json = Nokogiri::HTML(response.body).at_css("#app")["data-page"]
      JSON.parse(page_json).fetch("props")
    end
end
