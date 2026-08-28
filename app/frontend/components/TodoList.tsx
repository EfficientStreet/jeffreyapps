import { FormEvent } from "react"
import { useForm, usePage } from "@inertiajs/react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { TodoItem, type Todo } from "@/components/TodoItem"

import type { PageProps } from "@/types/inertia"

export type { Todo }

export function TodoList({ todos }: { todos: Todo[] }) {
  const { props } = usePage<PageProps>()
  const form = useForm({ description: "" })
  const errors = props.errors ?? {}

  const incomplete = todos.filter((todo) => !todo.completed)
  const completed = todos.filter((todo) => todo.completed)

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.post("/todos", {
      preserveScroll: true,
      onSuccess: () => form.reset("description"),
    })
  }

  return (
    <div className="space-y-8">
      <form onSubmit={submit} className="flex items-start gap-2">
        <div className="flex-1 space-y-1">
          <label htmlFor="todo-description" className="sr-only">
            New to-do
          </label>
          <Input
            id="todo-description"
            placeholder="Add a to-do…"
            autoComplete="off"
            aria-invalid={!!errors.description}
            value={form.data.description}
            onChange={(e) => form.setData("description", e.target.value)}
          />
          {errors.description && (
            <p className="text-xs text-danger-display">{errors.description}</p>
          )}
        </div>
        <Button type="submit" disabled={form.processing}>
          Add
        </Button>
      </form>

      <section>
        <h2 className="text-sm font-semibold text-ink-display">To-Dos</h2>
        {incomplete.length === 0 ? (
          <p className="mt-3 text-sm text-ink-muted">
            Nothing to do. Add a to-do above.
          </p>
        ) : (
          <ul className="mt-3 divide-y divide-hairline overflow-hidden rounded-md border border-hairline bg-page">
            {incomplete.map((todo) => (
              <TodoItem key={todo.id} todo={todo} />
            ))}
          </ul>
        )}
      </section>

      {completed.length > 0 && (
        <section>
          <h2 className="text-sm font-semibold text-ink-display">Completed</h2>
          <ul className="mt-3 divide-y divide-hairline overflow-hidden rounded-md border border-hairline bg-page">
            {completed.map((todo) => (
              <TodoItem key={todo.id} todo={todo} />
            ))}
          </ul>
        </section>
      )}
    </div>
  )
}
