# Milestone 4 — Summaries & sharing

## What's new in the app

- **Automatic AI summaries for bookmarks.** When you save a bookmark, a short summary of the page is generated in the background. The bookmark shows "Summarizing…" and then fills in the summary on its own — no refresh needed (the page quietly polls while a summary is pending).
- **Regenerate a summary.** The bookmark detail view has a "Regenerate" button that runs the summariser again and replaces the text.
- **Graceful failure.** If a page can't be fetched or the AI is unavailable, the summary area shows "Summary unavailable" and Regenerate can be retried. Works for both website and YouTube URLs. With no `ANTHROPIC_API_KEY` set, summaries just fail quietly — nothing crashes.
- **Share a bookmark by email.** A "Share" button on the bookmark detail view opens a small form: recipient email plus an editable, pre-filled subject and message. The message is seeded with the bookmark's title, its summary (if ready), and its URL.
- **Sending delivers a readable email** with the bookmark's title, URL, and summary — via Resend in production/staging, and previewed in the browser (`/letter_opener`) in development.
- The bookmark list also shows a one-line summary preview under each row ("Summarizing…", the summary text, or "Summary unavailable").

## What was built

### Gems (`Gemfile`, `Gemfile.lock`)
- `anthropic` (1.67.0) — official Anthropic SDK, used by `AiSummarizer`.
- `resend` (1.13.0) — official Resend SDK, the Action Mailer delivery method in production/staging.
- `dotenv-rails` (3.2.0), in `group :development, :test` — loads `ANTHROPIC_API_KEY` / `RESEND_API_KEY` from the repo-root `.env` (which already exists and is gitignored).

### Services (`app/services/`, ported verbatim from bookmarker)
- `ai_summarizer.rb` — `AiSummarizer.call(title:, content:)` → calls Claude (`claude-haiku-4-5`, `max_tokens: 1024`, `temperature: 0.3`, a fixed system prompt) with `Anthropic::Client.new(max_retries: 0)`. Never raises: blank `ANTHROPIC_API_KEY`, API errors, timeouts, and anything unexpected are logged and return `nil`.
- `bookmark_content_fetcher.rb` — `BookmarkContentFetcher.call(url, url_type)` → fetches the page (5s timeouts), strips `script/style/nav/header/footer/noscript/svg`, returns visible body text (≤ 12 000 chars, ≥ 40 chars or `nil`). For YouTube URLs it reads `og:description` / `meta[name=description]` instead. Never raises. `USER_AGENT` rebranded to `JeffreyAppsBot/1.0`.

### Job (`app/jobs/bookmark_summarization_job.rb`, ported verbatim)
- `BookmarkSummarizationJob.perform(bookmark_id)` — fetch content → if blank, mark `summary_status: :failed`; else summarise → if blank, `:failed`; else store `summary` + `:completed`. Always resolves to a terminal status, never re-raises, so Solid Queue never retries it. No-op if the bookmark was deleted.

### Mailer (`app/mailers/`, `app/views/share_mailer/`)
- `share_mailer.rb` — `ShareMailer.share(bookmark, to:, subject:, body:)`.
- `app/views/share_mailer/share.html.erb` (`simple_format(@body)`) + `share.text.erb` (`@body`).
- `application_mailer.rb` — default `from` changed `"from@example.com"` → `"no-reply@jeffreyapps.app"`.
- `test/mailers/previews/share_mailer_preview.rb` — preview at `/rails/mailers/share_mailer/share`.

### Config
- `config/initializers/resend.rb` — `Resend.api_key = ENV["RESEND_API_KEY"] if ENV["RESEND_API_KEY"].present?` (guarded so dev/test boot without the key).
- `config/environments/production.rb` + `staging.rb` — added `config.action_mailer.delivery_method = :resend`. (`default_url_options` left at the template's `host: "example.com"` — real deploy host wiring is milestone 5 / not done.)
- Development still uses `:letter_opener`; test still uses `:test`.

### Controller (`app/controllers/bookmarks_controller.rb`)
- `create` — now calls `BookmarkSummarizationJob.perform_later(bookmark.id)` after a successful save.
- `regenerate_summary` (POST, member) — `update!(summary_status: :pending)` + re-enqueue the job + redirect with a notice.
- `share` (POST, member) — validates `share_params` (`email` via `URI::MailTo::EMAIL_REGEXP`, `subject`/`body` presence) via `share_errors`; on error `redirect_back` with `inertia: { errors: }`; else `ShareMailer.share(...).deliver_later` + redirect with `"Bookmark shared with <email>."`.

### Routes (`config/routes.rb`)
- `resources :bookmarks` gained `member do post :regenerate_summary; post :share end`.

### Frontend
- `app/frontend/hooks/usePollWhilePending.ts` — ported verbatim. While `pending`, `router.reload({ showProgress: false })` every 3s; stops when `pending` flips false.
- `app/javascript/pages/bookmarks/Show.tsx` — `SummaryPlaceholder` replaced with `SummarySection` (renders the summary when `completed`, "Summarizing…" when `pending`, "Summary unavailable" when `failed`; a `soft` "Regenerate" button, disabled while pending). Added `ShareBookmarkDialog` (email + editable pre-filled subject/body via `buildDefaultBody`, payload wrapped under `share:`) to the header actions. `usePollWhilePending(bookmark.summary_status === "pending")` on the page.
- `app/javascript/pages/bookmarks/Index.tsx` — added `usePollWhilePending(...)` for the list and a `SummaryPreview` line under each row (140-char truncation; "Summarizing…" / "Summary unavailable" states).

### Tests (+24 → full suite is now 119 runs, 318 assertions, 0 failures/errors/skips)
- `test/services/ai_summarizer_test.rb` (5) — ported; WebMock-stubs `api.anthropic.com`; success, blank-key (no request), auth error, rate-limit, timeout.
- `test/services/bookmark_content_fetcher_test.rb` (7) — ported; body-text extraction + strip, YouTube `og:`/`name` description, timeout, non-2xx, too-short, `MAX_CHARS` truncation.
- `test/jobs/bookmark_summarization_job_test.rb` (4) — ported; completed-on-success, failed-on-no-content, failed-on-no-summary, no-op when bookmark gone.
- `test/mailers/share_mailer_test.rb` (1) — ported; recipient/subject/body in both parts.
- `test/controllers/bookmarks_controller_test.rb` — **re-added the 7 tests milestone 3 deferred**: `create enqueues a summarization job`; `regenerate_summary` resets+re-enqueues; `regenerate_summary` 404s for another user; `share` enqueues the email; `share` rejects bad email / blank subject+body without sending; `share` 404s for another user. Restored the `regenerate`/`share` lines in the unauth-redirect test.
- `test/application_system_test_case.rb` — `include ActiveJob::TestHelper` (matches bookmarker's base class).
- `test/system/bookmarks_test.rb` — the detail-view section updated for milestone 4: instead of asserting the placeholder + absence of Regenerate/Share, it drives the bookmark to `summary_status: :completed` via the shared test DB (the job itself is unit-tested), then asserts the summary text renders and that "Regenerate" + "Share" controls exist, and opens the Share dialog to confirm the pre-filled subject.

## Verification

- `bin/rubocop` — clean (87 files, 0 offenses).
- `npm run check` — clean.
- `bin/rails test` — **119 runs, 318 assertions, 0 failures, 0 errors, 0 skips** (3 consecutive green runs).
- `bin/rails test:system` — `bookmarks_test.rb` + `todos_test.rb`, green on 8 of 9 runs. One transient failure of `todos_test.rb` occurred in a back-to-back combined run right after the full suite + lint; it passes 5/5 in isolation and this is the pre-existing Inertia-hydration timing sensitivity the milestone-2 log already documents (retry helpers in place). No M4 test flaked.
- **Live browser check** (`PORT=4000 VITE_RUBY_PORT=4036 bin/dev`, real `ANTHROPIC_API_KEY` from `.env`):
  - Added a bookmark for `https://example.com` with no title → title auto-filled ("Example Domain"), row showed "Summarizing…".
  - The Solid Queue worker ran `BookmarkSummarizationJob` against the real Claude API; `usePollWhilePending` auto-refreshed the detail view to the generated summary ("This domain is designated for use in documentation and examples without requiring permission…") with no manual reload.
  - Clicked **Regenerate** → status went back to "Summarizing…", worker re-ran, page auto-refreshed to a fresh (reworded) summary.
  - Opened **Share** → subject pre-filled "Check out: Example Domain", message pre-filled with title + summary + URL. Filled recipient, sent → flash "Bookmark shared with friend@example.com."
  - `/letter_opener` showed the delivered email: from `no-reply@jeffreyapps.app`, subject "Check out: Example Domain", to `friend@example.com`, body containing the title, the AI summary, and `https://example.com` (multipart HTML + text).
  - Screenshot: `_build_plan/milestones/4-summaries-and-sharing/verify.png` (also `tmp/screenshots/m4-detail-summary.png`).

## Decisions not pre-specified in the PRD

- **Bookmarks that predate milestone 4 stay `pending` forever** (they never had a job enqueued). This only affects rows created during milestone-3 testing on a dev database; every bookmark created from milestone 4 on enqueues a job, so `pending` is always transient in normal use. The `Regenerate` button is disabled while `pending`, matching bookmarker — so a genuinely stuck `pending` row can't be retried from the UI. Not worth special-casing; a fresh DB (or milestone-5 deploy, which starts empty) has none.
- **`SummarySection` shows the plain "Summary unavailable" / "Summarizing…" copy from bookmarker**, not the milestone-3 "AI summary" card. The milestone-3 placeholder component (`SummaryPlaceholder`) was removed.
- **Mailer `from` address** is `no-reply@jeffreyapps.app` (a plausible brand address; not a verified Resend domain — irrelevant until deploy, since dev uses letter_opener and test uses `:test`).
- **`default_url_options` for production/staging** left at the template default `host: "example.com"`; wiring the real host is a deploy concern (milestone 5, not performed).
- **System test drives `summary_status` via the DB** rather than running the job through the queue in-process — the job is thoroughly unit-tested, and this keeps the system test deterministic and free of poll-timing races.

## Deviations from the PRD and why

- None of substance. All milestone-4 "What gets built" items are implemented: background summary on save, pending→text state, Regenerate action, "Summary unavailable" + retry for failures, website + YouTube support, Share form with editable pre-filled subject/body, and a readable email with title + URL + summary (Resend in production, browser preview in development).
- Explicitly **not** built (correctly out of scope): hand-editing the stored summary or choosing its length/style/language/model; summary version history or scheduled re-summarising; share history / open-click tracking / multiple recipients / attachments / scheduled sends; public share links; summarising or sharing to-dos.

## What milestone 5 needs to know

- Milestone 3's deferred tests are all restored — the bookmarks/tags/summaries/sharing suites are complete.
- The `summary` / `summary_status` columns and the `BookmarkSummarizationJob` pipeline are live; the dashboard's "recent bookmarks" snapshot can show `summary` / `summary_status` if useful (milestone-5 scope is links only).
- `dotenv-rails` now loads `.env` in dev and test. On deploy, `ANTHROPIC_API_KEY` and `RESEND_API_KEY` must be set in the Hatchbox environment (they are NOT committed).
- Production/staging mailer delivery is `:resend`; `default_url_options[:host]` still needs the real domain set at deploy time.
- `bin/dev` runs a Solid Queue worker; if the worker process is started before new files under `app/services`/`app/jobs` exist it will `NameError` on them (Zeitwerk, no reload in the worker) — restart `bin/dev` after adding job/service files. This bit the milestone-4 build once; a fresh boot resolved it.
