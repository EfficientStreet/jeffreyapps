import { Head, usePage } from "@inertiajs/react"
import { AppShell } from "@/components/AppShell"
import { TodoList, type Todo } from "@/components/TodoList"

import type { PageProps } from "@/types/inertia"

const DESCRIPTION =
  "Your to-do list — add tasks, check them off, edit, and delete."

export default function Todos({ todos }: { todos: Todo[] }) {
  const { props } = usePage<PageProps>()
  const user = props.current_user
  const rawName = user?.name || user?.email.split("@")[0]
  const displayName = rawName
    ? rawName.charAt(0).toUpperCase() + rawName.slice(1)
    : undefined

  return (
    <>
      <Head title="To-Dos">
        <meta name="description" content={DESCRIPTION} />
        <meta property="og:title" content="To-Dos" />
        <meta property="og:description" content={DESCRIPTION} />
      </Head>
      <AppShell>
        <h1>{displayName ? `${displayName}’s To-Dos` : "To-Dos"}</h1>
        <div className="mt-8">
          <TodoList todos={todos} />
        </div>
      </AppShell>
    </>
  )
}
