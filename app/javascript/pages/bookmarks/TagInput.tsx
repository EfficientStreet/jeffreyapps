import * as React from "react"
import { X } from "lucide-react"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"

export type TagSuggestion = { id: number; name: string }

type TagInputProps = {
  id?: string
  value: string[]
  onChange: (names: string[]) => void
  suggestions: TagSuggestion[]
  placeholder?: string
}

export function TagInput({ id, value, onChange, suggestions, placeholder }: TagInputProps) {
  const [text, setText] = React.useState("")
  const [open, setOpen] = React.useState(false)

  const normalizedValue = React.useMemo(() => value.map((name) => name.toLowerCase()), [value])

  const matches = React.useMemo(() => {
    const query = text.trim().toLowerCase()
    return suggestions
      .filter((tag) => !normalizedValue.includes(tag.name.toLowerCase()))
      .filter((tag) => (query ? tag.name.toLowerCase().includes(query) : true))
      .slice(0, 8)
  }, [suggestions, normalizedValue, text])

  function commit(rawName: string) {
    const name = rawName.trim()
    if (!name) return
    if (normalizedValue.includes(name.toLowerCase())) {
      setText("")
      return
    }
    onChange([...value, name])
    setText("")
  }

  function remove(name: string) {
    onChange(value.filter((existing) => existing !== name))
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Enter" || e.key === ",") {
      e.preventDefault()
      commit(text)
    } else if (e.key === "Backspace" && text === "" && value.length > 0) {
      remove(value[value.length - 1])
    }
  }

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap items-center gap-1.5">
        {value.map((name) => (
          <Badge key={name} tone="neutral" className="gap-1 pr-1">
            {name}
            <button
              type="button"
              onClick={() => remove(name)}
              aria-label={`Remove ${name}`}
              className="ml-0.5 inline-flex h-3.5 w-3.5 cursor-pointer items-center justify-center rounded-full text-ink-muted hover:bg-surface hover:text-ink-display"
            >
              <X className="h-3 w-3" />
            </button>
          </Badge>
        ))}
      </div>

      <div className="relative">
        <Input
          id={id}
          type="text"
          value={text}
          placeholder={placeholder ?? "Add a tag…"}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={handleKeyDown}
          onFocus={() => setOpen(true)}
          onBlur={() => setTimeout(() => setOpen(false), 100)}
        />

        {open && matches.length > 0 && (
          <ul
            className={cn(
              "absolute z-10 mt-1 max-h-48 w-full overflow-auto rounded-md border border-hairline bg-page p-1 shadow-lg",
            )}
          >
            {matches.map((tag) => (
              <li key={tag.id}>
                <button
                  type="button"
                  onMouseDown={(e) => e.preventDefault()}
                  onClick={() => commit(tag.name)}
                  className="flex w-full cursor-pointer items-center rounded-sm px-2 py-1.5 text-left text-sm text-ink-body hover:bg-surface hover:text-ink-display"
                >
                  {tag.name}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
