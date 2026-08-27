class TodosController < ApplicationController
  before_action :set_todo, only: %i[ update destroy ]

  def index
    render inertia: "Todos", props: {
      todos: Current.user.todos.ordered.map { |todo| todo_json(todo) }
    }
  end

  def create
    todo = Current.user.todos.build(todo_params)

    if todo.save
      redirect_to todos_path
    else
      redirect_to todos_path, inertia: { errors: todo.errors.to_hash(true).transform_values(&:first) }
    end
  end

  def update
    if @todo.update(todo_params)
      redirect_to todos_path
    else
      redirect_to todos_path, inertia: { errors: @todo.errors.to_hash(true).transform_values(&:first) }
    end
  end

  def destroy
    @todo.destroy
    redirect_to todos_path
  end

  private
    def set_todo
      @todo = Current.user.todos.find(params[:id])
    end

    def todo_params
      params.permit(:description, :completed)
    end

    def todo_json(todo)
      {
        id: todo.id,
        description: todo.description,
        completed: todo.completed,
        created_at: todo.created_at.iso8601
      }
    end
end
