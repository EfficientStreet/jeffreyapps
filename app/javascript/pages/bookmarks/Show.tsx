import * as React from "react"
import { FormEvent } from "react"
import { Head, Link, router, useForm, usePage } from "@inertiajs/react"
import { ArrowLeft, Globe, Mail, Pencil, RefreshCw, Trash2, Video } from "lucide-react"
import { AppShell } from "@/components/AppShell"
import { PageHeader } from "@/components/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { DataTable, DataRow } from "@/components/ui/data-table"
import { usePollWhilePending } from "@/hooks/usePollWhilePending"
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

  usePollWhilePending(bookmark.summary_status === "pending")

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
              <ShareBookmarkDialog bookmark={bookmark} />
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
            <SummarySection bookmark={bookmark} />
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

function SummarySection({ bookmark }: { bookmark: BookmarkDetail }) {
  const [regenerating, setRegenerating] = React.useState(false)
  const isPending = bookmark.summary_status === "pending"

  function regenerate() {
    setRegenerating(true)
    router.post(
      `/bookmarks/${bookmark.id}/regenerate_summary`,
      {},
      { preserveScroll: true, onFinish: () => setRegenerating(false) },
    )
  }

  return (
    <div className="flex items-start justify-between gap-4">
      {bookmark.summary_status === "completed" && bookmark.summary && (
        <p className="text-ink-body">{bookmark.summary}</p>
      )}
      {isPending && <p className="text-ink-muted">Summarizing&hellip;</p>}
      {bookmark.summary_status === "failed" && (
        <p className="text-ink-muted">Summary unavailable</p>
      )}
      <Button
        variant="soft"
        size="sm"
        disabled={isPending || regenerating}
        onClick={regenerate}
        className="shrink-0"
      >
        <RefreshCw className="h-3.5 w-3.5" /> {isPending ? "Summarizing…" : "Regenerate"}
      </Button>
    </div>
  )
}

function buildDefaultBody(bookmark: BookmarkDetail) {
  const lines = [ "I thought you'd find this interesting:", "", bookmark.title ]
  if (bookmark.summary_status === "completed" && bookmark.summary) {
    lines.push("", bookmark.summary)
  }
  lines.push("", bookmark.url)
  return lines.join("\n")
}

function ShareBookmarkDialog({ bookmark }: { bookmark: BookmarkDetail }) {
  const [open, setOpen] = React.useState(false)
  const { props } = usePage<PageProps>()
  const errors = props.errors ?? {}

  const form = useForm({
    email: "",
    subject: `Check out: ${bookmark.title}`,
    body: buildDefaultBody(bookmark),
  })

  // Recompute defaults each time the dialog opens, in case the summary
  // finished generating (or was regenerated) since it was last opened.
  function handleOpenChange(nextOpen: boolean) {
    if (nextOpen) {
      form.setData({
        email: "",
        subject: `Check out: ${bookmark.title}`,
        body: buildDefaultBody(bookmark),
      })
    }
    setOpen(nextOpen)
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    // Wrap explicitly under `share:` — none of these fields are real Bookmark
    // columns, so Rails' automatic params-wrapping wouldn't nest them correctly.
    form.transform((data) => ({ share: data }))
    form.post(`/bookmarks/${bookmark.id}/share`, {
      preserveScroll: true,
      onSuccess: () => setOpen(false),
    })
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogTrigger asChild>
        <Button variant="secondary">
          <Mail className="h-4 w-4" /> Share
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Share this bookmark</DialogTitle>
          <DialogDescription>Send it to a friend by email.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="space-y-2">
            <label htmlFor="share-email">Recipient email</label>
            <Input
              id="share-email"
              type="email"
              required
              placeholder="friend@example.com"
              aria-invalid={!!errors.email}
              value={form.data.email}
              onChange={(e) => form.setData("email", e.target.value)}
            />
            {errors.email && <p className="text-xs text-danger-display">{errors.email}</p>}
          </div>
          <div className="space-y-2">
            <label htmlFor="share-subject">Subject</label>
            <Input
              id="share-subject"
              type="text"
              required
              aria-invalid={!!errors.subject}
              value={form.data.subject}
              onChange={(e) => form.setData("subject", e.target.value)}
            />
            {errors.subject && <p className="text-xs text-danger-display">{errors.subject}</p>}
          </div>
          <div className="space-y-2">
            <label htmlFor="share-body">Message</label>
            <Textarea
              id="share-body"
              rows={7}
              required
              aria-invalid={!!errors.body}
              value={form.data.body}
              onChange={(e) => form.setData("body", e.target.value)}
            />
            {errors.body && <p className="text-xs text-danger-display">{errors.body}</p>}
          </div>
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={form.processing}>
              {form.processing ? "Sending…" : "Send"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
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
