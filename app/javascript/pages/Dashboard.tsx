import { Head, Link, usePage } from "@inertiajs/react"
import { ArrowRight, Bookmark as BookmarkIcon, Globe, ListChecks, Video } from "lucide-react"
import { AppShell } from "@/components/AppShell"
import { PageHeader } from "@/components/PageHeader"

import { type UrlType } from "@/lib/url-type"
import type { PageProps } from "@/types/inertia"

type OpenTodo = { id: number; description: string }
type RecentBookmark = {
  id: number
  title: string
  url: string
  url_type: UrlType
}

type DashboardProps = {
  open_todos_count: number
  open_todos: OpenTodo[]
  recent_bookmarks: RecentBookmark[]
}

function greetingName(name: string | null | undefined, email: string | undefined) {
  const raw = name?.trim() || email?.split("@")[0] || ""
  if (!raw) return "there"
  return raw.charAt(0).toUpperCase() + raw.slice(1)
}

export default function Dashboard() {
  const { props } = usePage<PageProps<DashboardProps>>()
  const user = props.current_user
  const { open_todos_count, open_todos, recent_bookmarks } = props

  return (
    <>
      <Head title="Home">
        <meta name="description" content="Your JeffreyApps home — a snapshot of your open to-dos and recent bookmarks." />
        <meta property="og:title" content="Home" />
        <meta property="og:description" content="Your JeffreyApps home — a snapshot of your open to-dos and recent bookmarks." />
      </Head>
      <AppShell>
        <PageHeader
          title="Home"
          description={`Welcome back, ${greetingName(user?.name, user?.email)}.`}
        />

        <div className="mt-8 grid grid-cols-1 gap-5 lg:grid-cols-2">
          {/* --- Open to-dos snapshot --- */}
          <section className="flex flex-col rounded-md border border-hairline bg-page p-5">
            <div className="flex items-center justify-between">
              <h2 className="flex items-center gap-2 text-sm font-semibold text-ink-display">
                <ListChecks className="h-4 w-4 text-ink-muted" /> To-Dos
              </h2>
              <span className="text-sm text-ink-muted">{open_todos_count} open</span>
            </div>

            {open_todos.length === 0 ? (
              <p className="mt-4 flex-1 text-sm text-ink-muted">
                {open_todos_count === 0
                  ? "Nothing open right now."
                  : "You're all caught up on the ones shown here."}
              </p>
            ) : (
              <ul className="mt-4 flex-1 divide-y divide-hairline">
                {open_todos.map((todo) => (
                  <li key={todo.id} className="truncate py-2 text-sm text-ink-body">
                    {todo.description}
                  </li>
                ))}
              </ul>
            )}

            <Link
              href="/todos"
              className="mt-4 inline-flex items-center gap-1 text-sm text-accent no-underline hover:underline"
            >
              View all to-dos <ArrowRight className="h-3.5 w-3.5" />
            </Link>
          </section>

          {/* --- Recent bookmarks snapshot --- */}
          <section className="flex flex-col rounded-md border border-hairline bg-page p-5">
            <h2 className="flex items-center gap-2 text-sm font-semibold text-ink-display">
              <BookmarkIcon className="h-4 w-4 text-ink-muted" /> Recent bookmarks
            </h2>

            {recent_bookmarks.length === 0 ? (
              <p className="mt-4 flex-1 text-sm text-ink-muted">No bookmarks saved yet.</p>
            ) : (
              <ul className="mt-4 flex-1 divide-y divide-hairline">
                {recent_bookmarks.map((bookmark) => (
                  <li key={bookmark.id} className="py-2">
                    <Link
                      href={`/bookmarks/${bookmark.id}`}
                      className="flex items-center gap-2 text-sm text-ink-body no-underline hover:text-ink-display"
                    >
                      {bookmark.url_type === "youtube" || bookmark.url_type === "tiktok" ? (
                        <Video className="h-3.5 w-3.5 shrink-0 text-ink-muted" />
                      ) : (
                        <Globe className="h-3.5 w-3.5 shrink-0 text-ink-muted" />
                      )}
                      <span className="truncate">{bookmark.title}</span>
                    </Link>
                  </li>
                ))}
              </ul>
            )}

            <Link
              href="/bookmarks"
              className="mt-4 inline-flex items-center gap-1 text-sm text-accent no-underline hover:underline"
            >
              View all bookmarks <ArrowRight className="h-3.5 w-3.5" />
            </Link>
          </section>
        </div>
      </AppShell>
    </>
  )
}
