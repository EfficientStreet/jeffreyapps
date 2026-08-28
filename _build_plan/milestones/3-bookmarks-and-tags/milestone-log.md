# Milestone 3 — Bookmarks & Tags

## What's new in the app

- **A Bookmarks page** at `/bookmarks` that lists everything you've saved, newest first, with a friendly empty state when you haven't saved anything yet.
- **Add a bookmark** from a dialog: paste a URL, optionally give it a title, notes, and tags. Leave the title blank and it auto-fills from the page's own `<title>` (falling back to the site's host name if the page can't be reached).
- **Website vs. YouTube detection:** the type is detected from the URL and shown as a badge ("Website" / "YouTube") on both the list and the detail view.
- **Bookmark detail view** at `/bookmarks/:id`: see the URL (as a link), type, notes, tags, and saved/updated timestamps. Edit the title and notes in a dialog; delete with a confirmation dialog.
- **Tagging by typing:** on a bookmark's detail view, type in the tag field — existing tags are suggested as you type, and brand-new tags are created on the fly. Tags are matched case-insensitively, so "Ruby" and "ruby" are the same tag.
- **Filter the list by a single tag:** tap a tag chip above the list to narrow it to bookmarks with that tag; a distinct empty state appears if none match, and "Clear filter" resets it.
- **A Tags page** at `/tags`, reached via the "Manage tags" button on the Bookmarks page (there is no sidebar item for it). It lists every tag with its bookmark count and lets you **rename**, **merge into another tag** (bookmarks re-point to the target, duplicates are de-duplicated, the source tag is deleted), and **delete** a tag. Deleting or merging a tag never deletes bookmarks. Empty state when you have no tags.
- **AI summary placeholder:** each bookmark detail view shows a calm "AI summary — Summaries aren't available yet." panel. Real summaries arrive in milestone 4.

## What was built

### Gems
- `Gemfile` — added `gem "nokogiri"` (HTML parsing for the page-title fetch) in the main section, and `gem "webmock"` in `group :test` (stub outbound HTTP in tests). `bundle install` run; `Gemfile.lock` updated. **Not** added: `anthropic`, `resend`, `dotenv-rails` (milestone 4).

### Data model / migrations
- `db/migrate/20260827000003_create_bookmarks.rb` — `bookmarks`: `user` ref (not null, FK), `url` (string, not null), `title` (string, not null), `url_type` (string, not null, default `"website"`), `summary` (text), `notes` (text), `summary_status` (string, not null, default `"pending"`), timestamps, plus `[:user_id, :created_at]` index. (bookmarker's `create_bookmarks` + `add_summary_status_to_bookmarks` folded into one, since this is a fresh table.)
- `db/migrate/20260827000004_create_tags.rb` — `tags`: `user` ref (not null, FK), `name` (string, not null), timestamps, plus a unique functional index `index_tags_on_user_id_and_lower_name` on `user_id, lower(name)`.
- `db/migrate/20260827000005_create_bookmark_tags.rb` — `bookmark_tags` join: `bookmark` ref + `tag` ref (both not null, FK), timestamps, unique index on `[:bookmark_id, :tag_id]`.
- Migrated; `db/schema.rb` bumped to version `2026_08_27_000005`.

### Models (ported verbatim from bookmarker)
- `app/models/bookmark.rb` — `belongs_to :user`; `has_many :bookmark_tags, dependent: :destroy`; `has_many :tags, through:`. Both enums kept: `enum :url_type, { website:, youtube: }, validate: true` and `enum :summary_status, { pending:, completed:, failed: }, validate: true` (the `summary_status` column/enum are part of the PRD data model even though nothing sets a non-`pending` value until milestone 4). `YOUTUBE_HOSTS`, `self.detect_url_type`, `url_valid_format?`, `url_must_be_http_or_https` validation, and `url`/`title` (≤500)/`notes` (≤10_000, allow_blank) validations.
- `app/models/tag.rb` — `normalizes :name` (strip); `name` presence, ≤50, uniqueness scoped to `:user_id`, case-insensitive.
- `app/models/bookmark_tag.rb` — `tag_id` uniqueness scoped to `bookmark_id`; `tag_and_bookmark_belong_to_same_user` validation.
- `app/models/user.rb` — added `has_many :bookmarks, dependent: :destroy` and `has_many :tags, dependent: :destroy`.

### Service
- `app/services/url_metadata_fetcher.rb` — ported from bookmarker. `Net::HTTP` + `Nokogiri`, 5s open/read timeouts, `Result = Struct.new(:title, :url_type, keyword_init: true)`. YouTube URLs try oEmbed first, then fall back to scraping the page `<title>`; websites scrape `<title>`; any failure falls back to the URL host. Never raises. `bookmark_content_fetcher.rb` and `ai_summarizer.rb` were **not** ported (milestone 4).

### Routes
- `config/routes.rb` — replaced the milestone-1 placeholder `resources :bookmarks, only: %i[ index ]` with:
  ```ruby
  resources :bookmarks, only: %i[ index show create update destroy ]
  resources :tags, only: %i[ index update destroy ] do
    member { post :merge }
  end
  ```
  `regenerate_summary` and `share` member routes were **not** added (milestone 4).

### Controllers
- `app/controllers/bookmarks_controller.rb` — ported from bookmarker with milestone-3 changes:
  - `index` — newest first, `includes(:tags)`, passes `bookmarks:` + `tags:`.
  - `show` — passes `bookmark:` + `all_tags:`.
  - `create` — `create_params` now permits `:title` too. Placeholder title = provided title (if present) else the URL. If `url_valid_format?`: always calls `UrlMetadataFetcher.call` and sets `url_type` from it; sets `title` from the fetched metadata **only when the user left the title blank**. `sync_tag_names` from `tag_names`. On save → `redirect_to bookmarks_path, notice: "Bookmark added."` — **no** `BookmarkSummarizationJob` (there is no job in milestone 3). On failure → `redirect_back … inertia: { errors: … }`.
  - `update` — `update_params` permits `:title, :notes`; `sync_tag_names` only when `tag_names` key is present (so a tags-only PATCH doesn't clobber the title).
  - `destroy` — deletes, redirects with notice.
  - `regenerate_summary`, `share`, and their private helpers (`share_params`, `share_errors`) were **removed** (milestone 4 re-adds them).
  - `bookmark_json` still includes `summary` and `summary_status` keys (columns exist).
- `app/controllers/tags_controller.rb` — full port: `index` (with `bookmarks_count`), `update` (rename), `destroy`, `merge` (conflict-dedup transaction: drop source join rows for bookmarks already on the target, repoint the rest, destroy the source; rejects a nil target, a self-merge, or another user's target).

### Frontend
- `app/frontend/components/ui/textarea.tsx` — new primitive (bookmarker had one; this template didn't). `form-control form-control-textarea` classes already existed in `design-system.css`.
- `app/javascript/pages/bookmarks/Index.tsx` — replaced the placeholder. List newest-first with a type badge + tag badges per row; "Add bookmark" dialog (URL + optional Title + optional Notes + `TagInput`); single-tag filter chips from the `tags` prop with a "Clear filter" control; empty state for no bookmarks and a separate empty state for "no bookmarks have that tag". "Manage tags" secondary button in the `PageHeader` actions is the only route to `/tags`. All four `<Head>` tags.
- `app/javascript/pages/bookmarks/Show.tsx` — new. `DataTable` of URL (link), Type (badge), Summary (neutral placeholder), Notes, Tags (`TagInput`), Saved, Updated. Edit dialog (title + notes) and Delete confirmation dialog (`size="sm"`). **No** Regenerate button, **no** Share button/form. All four `<Head>` tags.
- `app/javascript/pages/bookmarks/TagInput.tsx` — ported verbatim from bookmarker. Type to add (Enter or comma), Backspace on empty removes the last, suggestion dropdown filters existing tags, click a suggestion or type a new name.
- `app/javascript/pages/tags/Index.tsx` — new, ported from bookmarker's `tags/Index.tsx`. Tag rows with bookmark counts + a per-row dropdown menu (Rename / Merge into… / Delete). Rename & Merge dialogs (Merge uses a `<Select>` of the other tags), Delete confirmation dialog. Empty state. All four `<Head>` tags.
- Add/edit/rename forms wrap their payload under the model key explicitly (`form.transform((d) => ({ bookmark: d }))` / `({ tag: d })`) so virtual fields like `tag_names` are not dropped.

### Tests
- `test/test_helper.rb` — added `require "minitest/mock"`, `require "webmock/minitest"`, and `WebMock.disable_net_connect!(allow_localhost: true)`. **`allow_localhost: true` is load-bearing** — the SSR smoke test hits `localhost:13714` and Capybara needs the local server; blocking them breaks the suite. Verified `test/integration/ssr_smoke_test.rb` still passes.
- `test/fixtures/bookmarks.yml`, `tags.yml`, `bookmark_tags.yml` — ported from bookmarker (fixture names `rails_guides`, `youtube_talk`, `user_two_bookmark`, `ruby`, `rails`, `user_two_tag`, join rows `rails_guides_ruby` / `rails_guides_rails`).
- `test/models/bookmark_test.rb`, `test/models/tag_test.rb`, `test/models/bookmark_tag_test.rb` — full ports (incl. `summary_status` default + enum-validation tests, cascade tests).
- `test/services/url_metadata_fetcher_test.rb` — full port (WebMock `stub_request`).
- `test/controllers/tags_controller_test.rb` — full port.
- `test/controllers/bookmarks_controller_test.rb` — ported minus the 7 out-of-scope tests (see below), **plus** a new test `"create keeps a user-provided title instead of the fetched one"` proving the milestone-3 title reconciliation.
- `test/system/bookmarks_test.rb` — new, adapted from bookmarker's. Covers log in → empty state → add a bookmark with no title (title auto-fills from the stubbed page, "Website" badge shows) → detail view (asserts the neutral summary placeholder and the absence of Regenerate/Share) → edit title + notes and confirm they persist across a reload → tag from the detail view → filter the list by that tag and clear it → open the Tags page via "Manage tags" and rename the tag → delete the bookmark. Applies the Inertia+Capybara race rule (waiting assertions after every async submit/nav; a `refresh` after client-side nav; a retry-until-it-sticks helper for controlled inputs).

## Verification

- `bin/rails test` (full non-system suite incl. SSR smoke): **95 runs, 257 assertions, 0 failures, 0 errors, 0 skips**.
- `bin/rails test:system`: **2 runs, 33 assertions, 0 failures, 0 errors, 0 skips** — run 3× consecutively, all green (`todos_test.rb` + `bookmarks_test.rb`).
- `npm run check` (TypeScript): clean.
- `bin/rubocop` (rubocop-rails-omakase): clean, 0 offenses (77 files).
- Browser check at `http://localhost:4000` (dev server on `PORT=4000 VITE_RUBY_PORT=4036`): Bookmarks list (populated + empty states), add dialog, title auto-fill (real YouTube oEmbed title fetched for a `youtube.com/watch` URL; user-provided title kept when supplied), Website/YouTube badges, detail view (URL link, type badge, **neutral "AI summary — Summaries aren't available yet." placeholder, no Regenerate/Share controls**, Edit + Delete, tag input, timestamps), Tags page reached via "Manage tags" (rename / merge-into / delete menu; Merge correctly disabled when only one tag exists; bookmark counts), single-tag filter chip. Screenshots in `tmp/screenshots/m3-*.png` and `verify.png`.

### Gate note (post-crash resume)

The first `bin/rails test:system` run after resuming this milestone failed both system tests at `fill_in "Email"` on the login page. Root cause was **not** an M3 code defect: a leftover `bin/dev` (foreman + Puma + a Vite dev server in `--mode development`) from the interrupted build was still running, so `vite_rails` in the **test** environment detected a live dev server and emitted dev-mode `@vite/client` / `entrypoints/*` script tags that 404'd (the stray server serves `/vite-dev`, not `/vite-test`), leaving React unmounted. Killing the stray process tree fixed it; the built `public/vite-test/.vite/manifest.json` was already present. Nothing in the milestone-3 diff needed changing.

## Decisions not pre-specified in the PRD

- **Create-title reconciliation.** bookmarker always overwrites the title with the fetched one on create; the PRD says the title is "auto-filled from the page **if blank**". Resolved in favour of the PRD: `create_params` permits `:title`; the fetched title is applied only when `params.dig(:bookmark, :title).blank?`. A dedicated controller test (`"create keeps a user-provided title instead of the fetched one"`) locks this in. The add-bookmark dialog gained an optional Title field with the placeholder "Optional — auto-filled from the page".
- **Summary area = one neutral placeholder.** On the detail view the Summary `DataRow` renders a single calm panel ("AI summary" heading + "Summaries aren't available yet.") — it does **not** branch on `summary_status` and there is no Regenerate control. The list view shows no summary text at all. This avoids implying a working pipeline before milestone 4.
- **"Manage tags" entry point.** Placed as a `secondary` `<Button asChild><Link href="/tags">` in the Bookmarks `PageHeader` actions (next to "Add bookmark"). The Tags detail/back-link points to `/bookmarks`. No sidebar item was added (per the milestone-1 decision that Tags gets no nav entry).
- **Filter is single-tag.** bookmarker's Index supports a multi-tag AND filter plus a free-text search box. The PRD milestone-3 line is "Filter the bookmark list to a single tag", so the port was simplified to one selected tag id with a "Clear filter" affordance, and the free-text search box was dropped (full-text search is explicitly out of scope for this milestone).
- **`UrlMetadataFetcher::USER_AGENT`** string changed from `"BookmarkerBot/1.0 …"` to `"JeffreyAppsBot/1.0 …"` to match the app rebrand. No behavioural effect; not covered by any test.
- **Explicit params wrapping** on the add/edit/rename Inertia forms (`form.transform(... ({ bookmark|tag: data }))`) rather than relying on Rails' `ParamsWrapper`, matching bookmarker's add-form pattern and keeping virtual attributes (`tag_names`) intact.
- **`DeleteTagDialog` closes on success.** bookmarker's version left the confirm dialog mounted after a successful delete (it redirects back to `/tags`, the same page component, so Inertia re-renders rather than remounting and the parent's `activeDialog` state survives). Added `onSuccess: onClose` to the `router.delete` call so the dialog dismisses. Caught during the browser check.

## What the next milestone (4 — Summaries & Sharing) needs to know

- **7 bookmarker tests were deliberately not ported** (scoping, not weakening). Milestone 4 must add them back:
  1. `"create enqueues a summarization job for the new bookmark"` (bookmarks controller)
  2. `"regenerate_summary resets status to pending and re-enqueues the job"` (bookmarks controller)
  3. `"regenerate_summary on another user's bookmark 404s"` (bookmarks controller)
  4. `"share enqueues the email and redirects with a notice"` (bookmarks controller)
  5. `"share rejects an invalid email without sending"` (bookmarks controller)
  6. `"share rejects a blank subject or body without sending"` (bookmarks controller)
  7. `"share on another user's bookmark 404s"` (bookmarks controller)
  The current unauth-redirect test in `bookmarks_controller_test.rb` also had its `regenerate`/`share` lines trimmed — restore them.
- **Milestone 4 work items:**
  - Add `BookmarkSummarizationJob.perform_later(bookmark.id)` to `BookmarksController#create` (after `bookmark.save`).
  - Add the `regenerate_summary` (POST, member) and `share` (POST, member) routes, controller actions, and their private helpers (`share_params`, `share_errors`).
  - Re-add the Show-page UI: the `SummarySection` with completed/pending/failed branches + a "Regenerate" button, and the `ShareBookmarkDialog` (email/subject/body form; wrap payload under `share:`).
  - Port `app/services/ai_summarizer.rb` and `app/services/bookmark_content_fetcher.rb` (+ their tests) and `app/jobs/bookmark_summarization_job.rb`, and a `ShareMailer` (+ preview).
  - Add gems `anthropic`, `resend`, `dotenv-rails` and wire the API keys via `.env`.
  - Wire `summary_status` transitions (`pending` → `completed` / `failed`) inside the job.
- **Already in place for milestone 4:** the `summary` (text) and `summary_status` (string, default `"pending"`) columns exist on `bookmarks`; the `Bookmark` model already declares `enum :summary_status, { pending:, completed:, failed: }, validate: true`; `bookmark_json` already serialises both keys to the frontend.
- **`webmock`** is now a test dependency with `disable_net_connect!(allow_localhost: true)` — milestone 4's AI/email service tests should `stub_request` the Anthropic/Resend endpoints.
- `robots.txt` now also disallows `/tags`.

## Deviations from the PRD and why

- **No AI summary pipeline** — explicitly deferred by this milestone's scope; the summary area is a neutral placeholder.
- **No email sharing** — explicitly deferred.
- **Free-text search box removed** from the bookmark list (bookmarker had one) — full-text search is explicitly out of scope for milestone 3; only single-tag filtering is required.
- Nothing else in the PRD milestone-3 scope was skipped or changed.
