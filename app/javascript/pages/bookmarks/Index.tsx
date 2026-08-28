import * as React from "react"
import { FormEvent } from "react"
import { Head, Link, useForm, usePage } from "@inertiajs/react"
import { Bookmark as BookmarkIcon, Globe, Plus, Search, Tags, Video } from "lucide-react"
import { AppShell } from "@/components/AppShell"
import { PageHeader } from "@/components/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Badge } from "@/components/ui/badge"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { TagInput } from "./TagInput"
import { usePollWhilePending } from "@/hooks/usePollWhilePending"
import type { PageProps } from "@/types/inertia"

type BookmarkTag = { id: number; name: string }

type BookmarkRow = {
  id: number
  url: string
  title: string
  url_type: "website" | "youtube"
  notes: string | null
  summary: string | null
  summary_status: "pending" | "completed" | "failed"
  created_at: string
  updated_at: string
  tags: BookmarkTag[]
}

type BookmarksIndexProps = { bookmarks: BookmarkRow[]; tags: BookmarkTag[] }

const DESCRIPTION =
  "Save, tag, and filter your bookmarked websites and YouTube videos."

export default function BookmarksIndex() {
  const { props } = usePage<PageProps<BookmarksIndexProps>>()
  const { bookmarks, tags } = props

  const user = props.current_user
  const rawName = user?.name || user?.email.split("@")[0]
  const displayName = rawName
    ? rawName.charAt(0).toUpperCase() + rawName.slice(1)
    : undefined

  usePollWhilePending(bookmarks.some((bookmark) => bookmark.summary_status === "pending"))

  const [selectedTagId, setSelectedTagId] = React.useState<number | null>(null)

  const filteredBookmarks = React.useMemo(() => {
    if (selectedTagId === null) return bookmarks
    return bookmarks.filter((bookmark) =>
      bookmark.tags.some((tag) => tag.id === selectedTagId),
    )
  }, [bookmarks, selectedTagId])

  function toggleTag(id: number) {
    setSelectedTagId((current) => (current === id ? null : id))
  }

  const hasAnyBookmarks = bookmarks.length > 0

  return (
    <>
      <Head title="Bookmarks">
        <meta name="description" content={DESCRIPTION} />
        <meta property="og:title" content="Bookmarks" />
        <meta property="og:description" content={DESCRIPTION} />
      </Head>
      <AppShell>
        <PageHeader
          title={displayName ? `${displayName}’s Bookmarks` : "Bookmarks"}
          description={`${bookmarks.length} ${bookmarks.length === 1 ? "bookmark" : "bookmarks"} saved.`}
          actions={
            <>
              <Button variant="secondary" asChild>
                <Link href="/tags" className="no-underline">
                  <Tags className="h-4 w-4" /> Manage tags
                </Link>
              </Button>
              <AddBookmarkDialog tags={tags} />
            </>
          }
        />

        {props.flash?.notice && (
          <p className="mt-6 text-sm text-accent">{props.flash.notice}</p>
        )}

        {hasAnyBookmarks && tags.length > 0 && (
          <div className="mt-6 flex flex-wrap items-center gap-1.5">
            <span className="mr-1 text-sm text-ink-muted">Filter by tag:</span>
            {tags.map((tag) => {
              const selected = selectedTagId === tag.id
              return (
                <button
                  key={tag.id}
                  type="button"
                  onClick={() => toggleTag(tag.id)}
                  className="cursor-pointer"
                  data-testid={`tag-filter-${tag.id}`}
                >
                  <Badge tone={selected ? "accent" : "neutral"}>{tag.name}</Badge>
                </button>
              )
            })}
            {selectedTagId !== null && (
              <button
                type="button"
                onClick={() => setSelectedTagId(null)}
                className="ml-1 cursor-pointer text-sm text-ink-muted underline"
              >
                Clear filter
              </button>
            )}
          </div>
        )}

        {!hasAnyBookmarks && (
          <div className="mt-10 flex flex-col items-center gap-3 rounded-md border border-dashed border-hairline py-16 text-center">
            <BookmarkIcon className="h-8 w-8 text-ink-muted" />
            <div>
              <p className="font-medium text-ink-display">You haven&rsquo;t added any bookmarks yet</p>
              <p className="mt-1 text-sm text-ink-muted">Paste a URL to save your first website or YouTube video.</p>
            </div>
            <AddBookmarkDialog tags={tags} triggerLabel="Add your first bookmark" />
          </div>
        )}

        {hasAnyBookmarks && filteredBookmarks.length === 0 && (
          <div className="mt-10 flex flex-col items-center gap-3 py-16 text-center">
            <Search className="h-8 w-8 text-ink-muted" />
            <p className="font-medium text-ink-display">No bookmarks have that tag</p>
            <Button variant="ghost" onClick={() => setSelectedTagId(null)}>
              Clear filter
            </Button>
          </div>
        )}

        {hasAnyBookmarks && filteredBookmarks.length > 0 && (
          <ul className="mt-6 divide-y divide-hairline overflow-hidden rounded-md border border-hairline bg-page">
            {filteredBookmarks.map((bookmark) => (
              <li key={bookmark.id}>
                <Link
                  href={`/bookmarks/${bookmark.id}`}
                  className="flex items-start gap-3 px-4 py-3 no-underline hover:bg-surface"
                >
                  {bookmark.url_type === "youtube" ? (
                    <Video className="mt-0.5 h-4 w-4 shrink-0 text-ink-muted" />
                  ) : (
                    <Globe className="mt-0.5 h-4 w-4 shrink-0 text-ink-muted" />
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-sm font-medium text-ink-display">{bookmark.title}</div>
                    <div className="truncate text-xs text-ink-muted">{bookmark.url}</div>
                    <div className="mt-1.5 flex flex-wrap items-center gap-1">
                      <Badge tone={bookmark.url_type === "youtube" ? "signal" : "muted"}>
                        {bookmark.url_type === "youtube" ? "YouTube" : "Website"}
                      </Badge>
                      {bookmark.tags.map((tag) => (
                        <Badge key={tag.id} tone="neutral">
                          {tag.name}
                        </Badge>
                      ))}
                    </div>
                    <SummaryPreview bookmark={bookmark} />
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </AppShell>
    </>
  )
}

const SUMMARY_PREVIEW_MAX_CHARS = 140

function SummaryPreview({ bookmark }: { bookmark: BookmarkRow }) {
  if (bookmark.summary_status === "pending") {
    return <p className="mt-1.5 text-xs text-ink-muted">Summarizing&hellip;</p>
  }
  if (bookmark.summary_status === "failed") {
    return <p className="mt-1.5 text-xs text-ink-muted">Summary unavailable</p>
  }
  if (!bookmark.summary) return null

  const preview =
    bookmark.summary.length > SUMMARY_PREVIEW_MAX_CHARS
      ? `${bookmark.summary.slice(0, SUMMARY_PREVIEW_MAX_CHARS).trimEnd()}…`
      : bookmark.summary
  return <p className="mt-1.5 text-xs text-ink-muted">{preview}</p>
}

function AddBookmarkDialog({ tags, triggerLabel }: { tags: BookmarkTag[]; triggerLabel?: string }) {
  const [open, setOpen] = React.useState(false)
  const { props } = usePage<PageProps>()
  const errors = props.errors ?? {}

  const form = useForm({ url: "", title: "", notes: "", tag_names: [] as string[] })

  const submit = (e: FormEvent) => {
    e.preventDefault()
    // Wrap explicitly under `bookmark:` — Rails only auto-nests real column
    // names (url, title, notes) into that key, so tag_names (a virtual
    // attribute) would otherwise arrive at the top level and get dropped.
    form.transform((data) => ({ bookmark: data }))
    form.post("/bookmarks", {
      preserveScroll: true,
      onSuccess: () => {
        form.reset()
        setOpen(false)
      },
    })
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
          <Plus className="h-4 w-4" /> {triggerLabel ?? "Add bookmark"}
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add a bookmark</DialogTitle>
          <DialogDescription>
            Paste a URL. Leave the title blank to auto-fill it from the page.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="space-y-2">
            <label htmlFor="bookmark-url">URL</label>
            <Input
              id="bookmark-url"
              type="url"
              inputMode="url"
              autoComplete="off"
              required
              placeholder="https://example.com"
              aria-invalid={!!errors.url}
              value={form.data.url}
              onChange={(e) => form.setData("url", e.target.value)}
            />
            {errors.url && <p className="text-xs text-danger-display">{errors.url}</p>}
          </div>

          <div className="space-y-2">
            <label htmlFor="bookmark-title">Title</label>
            <Input
              id="bookmark-title"
              type="text"
              autoComplete="off"
              placeholder="Optional — auto-filled from the page"
              aria-invalid={!!errors.title}
              value={form.data.title}
              onChange={(e) => form.setData("title", e.target.value)}
            />
            {errors.title && <p className="text-xs text-danger-display">{errors.title}</p>}
          </div>

          <div className="space-y-2">
            <label htmlFor="bookmark-notes">Notes</label>
            <Textarea
              id="bookmark-notes"
              placeholder="Optional notes…"
              value={form.data.notes}
              onChange={(e) => form.setData("notes", e.target.value)}
            />
          </div>

          <div className="space-y-2">
            <label htmlFor="bookmark-tags">Tags</label>
            <TagInput
              id="bookmark-tags"
              value={form.data.tag_names}
              onChange={(names) => form.setData("tag_names", names)}
              suggestions={tags}
            />
          </div>

          <DialogFooter>
            <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={form.processing}>
              {form.processing ? "Adding…" : "Add bookmark"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
