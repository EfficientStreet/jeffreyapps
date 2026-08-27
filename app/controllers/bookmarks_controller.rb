class BookmarksController < ApplicationController
  def index
    render inertia: "bookmarks/Index"
  end
end
