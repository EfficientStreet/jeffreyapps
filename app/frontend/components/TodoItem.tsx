import { KeyboardEvent, useState } from "react"
import { router } from "@inertiajs/react"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Input } from "@/components/ui/input"
import { cn } from "@/lib/utils"
import { Trash2 } from "lucide-react"

export type Todo = {
  id: number
  description: string
  completed: boolean
  created_at: string
}

export function TodoItem({ todo }: { todo: Todo }) {
  const [isEditing, setIsEditing] = useState(false)
  const [draft, setDraft] = useState(todo.description)

  const toggleCompleted = () => {
    router.patch(`/todos/${todo.id}`, { completed: !todo.completed }, { preserveScroll: true })
  }

  const startEditing = () => {
    setDraft(todo.description)
    setIsEditing(true)
  }

  const saveEdit = () => {
    const trimmed = draft.trim()
    setIsEditing(false)
    if (trimmed && trimmed !== todo.description) {
      router.patch(`/todos/${todo.id}`, { description: trimmed }, { preserveScroll: true })
    } else {
      setDraft(todo.description)
    }
  }

  const cancelEdit = () => {
    setDraft(todo.description)
    setIsEditing(false)
  }

  const handleKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault()
      saveEdit()
    } else if (e.key === "Escape") {
      e.preventDefault()
      cancelEdit()
    }
  }

  const destroy = () => {
    router.delete(`/todos/${todo.id}`, { preserveScroll: true })
  }

  return (
    <li>
      <div className="flex items-center gap-3 px-4 py-3">
        <Checkbox
          checked={todo.completed}
          onChange={toggleCompleted}
          aria-label={todo.completed ? "Mark as incomplete" : "Mark as complete"}
        />
        <div className="min-w-0 flex-1">
          {isEditing ? (
            <Input
              autoFocus
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              onBlur={saveEdit}
              onKeyDown={handleKeyDown}
              aria-label="Edit to-do description"
            />
          ) : (
            <button
              type="button"
              onClick={startEditing}
              className={cn(
                "-mx-1 block w-full truncate rounded px-1 py-0.5 text-left text-sm text-ink-body hover:bg-surface",
                todo.completed && "text-ink-muted line-through",
              )}
            >
              {todo.description}
            </button>
          )}
        </div>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          aria-label="Delete to-do"
          onClick={destroy}
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      </div>
    </li>
  )
}
