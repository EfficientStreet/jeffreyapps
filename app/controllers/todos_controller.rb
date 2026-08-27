class TodosController < ApplicationController
  def index
    render inertia: "Todos"
  end
end
