class DashboardController < ApplicationController
  SNAPSHOT_LIMIT = 5

  def show
    todos = Current.user.todos
    open_todos = todos.where(completed: false).order(created_at: :asc)
    recent_bookmarks = Current.user.bookmarks.order(created_at: :desc).limit(SNAPSHOT_LIMIT)

    render inertia: "Dashboard", props: {
      open_todos_count: open_todos.count,
      open_todos: open_todos.limit(SNAPSHOT_LIMIT).map { |todo|
        { id: todo.id, description: todo.description }
      },
      recent_bookmarks: recent_bookmarks.map { |bookmark|
        {
          id: bookmark.id,
          title: bookmark.title,
          url: bookmark.url,
          url_type: bookmark.url_type
        }
      }
    }
  end
end
