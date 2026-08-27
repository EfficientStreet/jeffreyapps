import * as React from "react"
import { FormEvent } from "react"
import { Head, Link, router, useForm, usePage } from "@inertiajs/react"
import { ArrowLeft, Globe, Pencil, Sparkles, Trash2, Video } from "lucide-react"
import { AppShell } from "@/components/AppShell"
import { PageHeader } from "@/components/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { DataTable, DataRow } from "@/components/ui/data-table"
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
import type { PageProps } from "@/types/inertia"

type BookmarkTag = { id: number; name: string }

type SummaryStatus = "pending" | "completed" | "failed"

type BookmarkDetail = {
  id: number
  url: string
  title: string
  url_type: "website" | "youtube"
  notes: string | null
  summary: string | null
  summary_status: SummaryStatus
  created_at: string
  updated_at: string
  tags: BookmarkTag[]
}

type BookmarksShowProps = { bookmark: BookmarkDetail; all_tags: BookmarkTag[] }

export default function BookmarksShow() {
  const { props } = usePage<PageProps<BookmarksShowProps>>()
  const { bookmark, all_tags } = props

  function updateTags(names: string[]) {
    router.patch(
      `/bookmarks/${bookmark.id}`,
      { bookmark: { tag_names: names } },
      { preserveScroll: true },
    )
  }

  return (
    <>
      <Head title={bookmark.title}>
        <meta name="description" content={`Bookmark detail for ${bookmark.title}.`} />
        <meta property="og:title" content={bookmark.title} />
        <meta property="og:description" content={`Bookmark detail for ${bookmark.title}.`} />
      </Head>
      <AppShell>
        <PageHeader
          title={bookmark.title}
          description={
            <Link href="/bookmarks" className="inline-flex items-center gap-1 text-sm text-ink-muted no-underline hover:text-ink-display">
              <ArrowLeft className="h-3.5 w-3.5" /> Back to bookmarks
            </Link>
          }
          actions={
            <>
              <EditBookmarkDialog bookmark={bookmark} />
              <DeleteBookmarkDialog bookmark={bookmark} />
            </>
          }
        />

        {props.flash?.notice && (
          <p className="mt-6 text-sm text-accent">{props.flash.notice}</p>
        )}

        <DataTable className="mt-6">
          <DataRow title="URL">
            <a href={bookmark.url} target="_blank" rel="noopener noreferrer">
              {bookmark.url}
            </a>
          </DataRow>
          <DataRow title="Type">
            <span className="inline-flex items-center gap-1.5">
              {bookmark.url_type === "youtube" ? (
                <Video className="h-4 w-4 text-ink-muted" />
              ) : (
                <Globe className="h-4 w-4 text-ink-muted" />
              )}
              {bookmark.url_type === "youtube" ? "YouTube" : "Website"}
            </span>
          </DataRow>
          <DataRow title="Summary">
            <SummaryPlaceholder />
          </DataRow>
          <DataRow title="Notes">
            {bookmark.notes || <span className="text-ink-muted">&mdash;</span>}
          </DataRow>
          <DataRow title="Tags">
            <TagInput
              id="bookmark-tags-show"
              value={bookmark.tags.map((tag) => tag.name)}
              onChange={updateTags}
              suggestions={all_tags}
            />
          </DataRow>
          <DataRow title="Saved">{formatDateTime(bookmark.created_at)}</DataRow>
          <DataRow title="Updated">{formatDateTime(bookmark.updated_at)}</DataRow>
        </DataTable>
      </AppShell>
    </>
  )
}

// AI summaries arrive in a later milestone. Until then the summary area shows a
// single calm placeholder rather than any working-pipeline state.
function SummaryPlaceholder() {
  return (
    <div className="flex items-start gap-3 rounded-md border border-hairline bg-surface px-4 py-3">
      <Sparkles className="mt-0.5 h-4 w-4 shrink-0 text-ink-muted" />
      <div>
        <p className="font-medium text-ink-display">AI summary</p>
        <p className="mt-0.5 text-sm text-ink-muted">Summaries aren&rsquo;t available yet.</p>
      </div>
    </div>
  )
}

function EditBookmarkDialog({ bookmark }: { bookmark: BookmarkDetail }) {
  const [open, setOpen] = React.useState(false)
  const { props } = usePage<PageProps>()
  const errors = props.errors ?? {}

  const form = useForm({ title: bookmark.title, notes: bookmark.notes ?? "" })

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((data) => ({ bookmark: data }))
    form.patch(`/bookmarks/${bookmark.id}`, {
      preserveScroll: true,
      onSuccess: () => setOpen(false),
    })
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
          <Pencil className="h-4 w-4" /> Edit
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Edit bookmark</DialogTitle>
          <DialogDescription>Update the title and notes.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="space-y-2">
            <label htmlFor="edit-title">Title</label>
            <Input
              id="edit-title"
              type="text"
              required
              aria-invalid={!!errors.title}
              value={form.data.title}
              onChange={(e) => form.setData("title", e.target.value)}
            />
            {errors.title && <p className="text-xs text-danger-display">{errors.title}</p>}
          </div>
          <div className="space-y-2">
            <label htmlFor="edit-notes">Notes</label>
            <Textarea
              id="edit-notes"
              value={form.data.notes}
              onChange={(e) => form.setData("notes", e.target.value)}
            />
          </div>
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={form.processing}>
              {form.processing ? "Saving…" : "Save changes"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function DeleteBookmarkDialog({ bookmark }: { bookmark: BookmarkDetail }) {
  const [open, setOpen] = React.useState(false)
  const [processing, setProcessing] = React.useState(false)

  function confirmDelete() {
    setProcessing(true)
    router.delete(`/bookmarks/${bookmark.id}`)
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="danger">
          <Trash2 className="h-4 w-4" /> Delete
        </Button>
      </DialogTrigger>
      <DialogContent size="sm">
        <DialogHeader>
          <DialogTitle>Delete this bookmark?</DialogTitle>
          <DialogDescription>
            &ldquo;{bookmark.title}&rdquo; will be permanently removed. This can&rsquo;t be undone.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
            Cancel
          </Button>
          <Button type="button" variant="danger" disabled={processing} onClick={confirmDelete}>
            {processing ? "Deleting…" : "Delete"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function formatDateTime(iso: string) {
  return new Date(iso).toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  })
}
