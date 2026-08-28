import * as React from "react"
import { FormEvent } from "react"
import { Head, Link, router, useForm, usePage } from "@inertiajs/react"
import { ArrowLeft, GitMerge, MoreVertical, Pencil, Tag as TagIcon, Trash2 } from "lucide-react"
import { AppShell } from "@/components/AppShell"
import { PageHeader } from "@/components/PageHeader"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select } from "@/components/ui/select"
import { Badge } from "@/components/ui/badge"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import type { PageProps } from "@/types/inertia"

type TagRow = { id: number; name: string; bookmarks_count: number }
type TagsIndexProps = { tags: TagRow[] }

type ActiveDialog =
  | { kind: "rename"; tag: TagRow }
  | { kind: "delete"; tag: TagRow }
  | { kind: "merge"; tag: TagRow }
  | null

const DESCRIPTION = "Rename, delete, or merge the tags on your bookmarks."

export default function TagsIndex() {
  const { props } = usePage<PageProps<TagsIndexProps>>()
  const { tags } = props
  const [activeDialog, setActiveDialog] = React.useState<ActiveDialog>(null)

  return (
    <>
      <Head title="Tags">
        <meta name="description" content={DESCRIPTION} />
        <meta property="og:title" content="Tags" />
        <meta property="og:description" content={DESCRIPTION} />
      </Head>
      <AppShell>
        <PageHeader
          title="Tags"
          description={
            <Link href="/bookmarks" className="inline-flex items-center gap-1 text-sm text-ink-muted no-underline hover:text-ink-display">
              <ArrowLeft className="h-3.5 w-3.5" /> Back to bookmarks
            </Link>
          }
        />

        {props.flash?.notice && (
          <p className="mt-6 text-sm text-accent">{props.flash.notice}</p>
        )}

        {tags.length === 0 ? (
          <div className="mt-10 flex flex-col items-center gap-3 rounded-md border border-dashed border-hairline py-16 text-center">
            <TagIcon className="h-8 w-8 text-ink-muted" />
            <div>
              <p className="font-medium text-ink-display">You haven&rsquo;t created any tags yet</p>
              <p className="mt-1 text-sm text-ink-muted">
                Add tags to your bookmarks to see them here.
              </p>
            </div>
          </div>
        ) : (
          <ul className="mt-6 divide-y divide-hairline overflow-hidden rounded-md border border-hairline bg-page">
            {tags.map((tag) => (
              <li key={tag.id} className="flex items-center gap-3 px-4 py-3">
                <TagIcon className="h-4 w-4 shrink-0 text-ink-muted" />
                <div className="min-w-0 flex-1">
                  <div className="truncate text-sm font-medium text-ink-display">{tag.name}</div>
                </div>
                <Badge tone="muted">
                  {tag.bookmarks_count} {tag.bookmarks_count === 1 ? "bookmark" : "bookmarks"}
                </Badge>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="icon" aria-label={`Actions for ${tag.name}`}>
                      <MoreVertical className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onSelect={() => setActiveDialog({ kind: "rename", tag })}>
                      <Pencil /> Rename
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      disabled={tags.length < 2}
                      onSelect={() => setActiveDialog({ kind: "merge", tag })}
                    >
                      <GitMerge /> Merge into&hellip;
                    </DropdownMenuItem>
                    <DropdownMenuItem destructive onSelect={() => setActiveDialog({ kind: "delete", tag })}>
                      <Trash2 /> Delete
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </li>
            ))}
          </ul>
        )}
      </AppShell>

      <RenameTagDialog
        tag={activeDialog?.kind === "rename" ? activeDialog.tag : null}
        onClose={() => setActiveDialog(null)}
      />
      <DeleteTagDialog
        tag={activeDialog?.kind === "delete" ? activeDialog.tag : null}
        onClose={() => setActiveDialog(null)}
      />
      <MergeTagDialog
        tag={activeDialog?.kind === "merge" ? activeDialog.tag : null}
        tags={tags}
        onClose={() => setActiveDialog(null)}
      />
    </>
  )
}

function RenameTagDialog({ tag, onClose }: { tag: TagRow | null; onClose: () => void }) {
  const { props } = usePage<PageProps>()
  const errors = props.errors ?? {}
  const form = useForm({ name: tag?.name ?? "" })

  React.useEffect(() => {
    if (tag) form.setData("name", tag.name)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tag?.id])

  const submit = (e: FormEvent) => {
    e.preventDefault()
    if (!tag) return
    form.transform((data) => ({ tag: data }))
    form.patch(`/tags/${tag.id}`, { preserveScroll: true, onSuccess: onClose })
  }

  return (
    <Dialog open={!!tag} onOpenChange={(open) => !open && onClose()}>
      <DialogContent size="sm">
        <DialogHeader>
          <DialogTitle>Rename tag</DialogTitle>
          <DialogDescription>This renames the tag everywhere it&rsquo;s used.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="space-y-2">
            <label htmlFor="tag-name">Name</label>
            <Input
              id="tag-name"
              type="text"
              required
              aria-invalid={!!errors.name}
              value={form.data.name}
              onChange={(e) => form.setData("name", e.target.value)}
            />
            {errors.name && <p className="text-xs text-danger-display">{errors.name}</p>}
          </div>
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={form.processing}>
              {form.processing ? "Saving…" : "Rename"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function DeleteTagDialog({ tag, onClose }: { tag: TagRow | null; onClose: () => void }) {
  const [processing, setProcessing] = React.useState(false)

  function confirmDelete() {
    if (!tag) return
    setProcessing(true)
    // Deleting redirects back to /tags (the same page component), so Inertia
    // re-renders rather than remounting — close the dialog explicitly.
    router.delete(`/tags/${tag.id}`, {
      onSuccess: onClose,
      onFinish: () => setProcessing(false),
    })
  }

  return (
    <Dialog open={!!tag} onOpenChange={(open) => !open && onClose()}>
      <DialogContent size="sm">
        <DialogHeader>
          <DialogTitle>Delete this tag?</DialogTitle>
          <DialogDescription>
            {tag && (
              <>
                &ldquo;{tag.name}&rdquo; will be removed from {tag.bookmarks_count}{" "}
                {tag.bookmarks_count === 1 ? "bookmark" : "bookmarks"}. The bookmarks themselves are not deleted.
              </>
            )}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button type="button" variant="ghost" onClick={onClose}>
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

function MergeTagDialog({ tag, tags, onClose }: { tag: TagRow | null; tags: TagRow[]; onClose: () => void }) {
  const { props } = usePage<PageProps>()
  const errors = props.errors ?? {}
  const otherTags = tag ? tags.filter((t) => t.id !== tag.id) : []
  const form = useForm({ target_tag_id: "" })

  React.useEffect(() => {
    form.setData("target_tag_id", otherTags[0] ? String(otherTags[0].id) : "")
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tag?.id])

  const submit = (e: FormEvent) => {
    e.preventDefault()
    if (!tag) return
    form.post(`/tags/${tag.id}/merge`, { preserveScroll: true, onSuccess: onClose })
  }

  return (
    <Dialog open={!!tag} onOpenChange={(open) => !open && onClose()}>
      <DialogContent size="sm">
        <DialogHeader>
          <DialogTitle>Merge tag</DialogTitle>
          <DialogDescription>
            {tag && (
              <>
                Every bookmark tagged &ldquo;{tag.name}&rdquo; will be retagged with the tag you choose, and
                &ldquo;{tag.name}&rdquo; will be deleted.
              </>
            )}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="space-y-2">
            <label htmlFor="merge-target">Merge into</label>
            <Select
              id="merge-target"
              value={form.data.target_tag_id}
              onChange={(e) => form.setData("target_tag_id", e.target.value)}
            >
              {otherTags.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </Select>
            {errors.target_tag_id && <p className="text-xs text-danger-display">{errors.target_tag_id}</p>}
          </div>
          <DialogFooter>
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={form.processing || otherTags.length === 0}>
              {form.processing ? "Merging…" : "Merge"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
