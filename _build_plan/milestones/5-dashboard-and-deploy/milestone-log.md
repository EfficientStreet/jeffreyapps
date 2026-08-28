# Milestone 5 — Dashboard & deploy

> **Status: dashboard done and verified locally; production deploy deferred (see "Deviations").**

## What's new in the app

- **The Home page is now a real dashboard.** Instead of a bare "Welcome to your account" line it shows a personalised greeting plus two at-a-glance panels.
- **Open to-dos snapshot** — a count of everything still open ("N open") and the next few incomplete items, in the same order they appear on the To-Dos page.
- **Recent bookmarks snapshot** — your five most recently saved bookmarks, newest first, each with a website/YouTube icon and linking straight to its detail view.
- **Both panels link through to their full page** ("View all to-dos →", "View all bookmarks →").
- Sensible empty states: "Nothing open right now." when you have no open to-dos, "No bookmarks saved yet." when you have none.
- The greeting uses your profile **Name** if set, otherwise the part of your email before the `@`, otherwise "there".

## What was built

### Backend — `app/controllers/dashboard_controller.rb`
- `DashboardController#show` now returns real Inertia props instead of `render inertia: "Dashboard"` with nothing:
  - `open_todos_count` — `Current.user.todos.where(completed: false).count` (the full count, not capped).
  - `open_todos` — the first `SNAPSHOT_LIMIT` (5) of those, ordered `created_at: :asc` (same order as the To-Dos page's open section), each as `{ id, description }`.
  - `recent_bookmarks` — `Current.user.bookmarks.order(created_at: :desc).limit(5)`, each as `{ id, title, url, url_type }`.
- `SNAPSHOT_LIMIT = 5` constant on the controller.
- Everything is scoped through `Current.user` — the same per-user scoping every other controller in the app uses. No cross-user leakage.

### Frontend — `app/javascript/pages/Dashboard.tsx`
- Typed the page props (`DashboardProps` = `open_todos_count` / `open_todos` / `recent_bookmarks`); `usePage<PageProps<DashboardProps>>()`.
- Replaced the bare `<h1>Home</h1>` + welcome line with the shared `<PageHeader>` (title "Home", description `Welcome back, {greetingName(...)}.`).
- `greetingName(name, email)` helper: trimmed profile name → else `email.split("@")[0]` → else `"there"`, first letter upper-cased.
- Two `<section>` cards in a `grid grid-cols-1 gap-5 lg:grid-cols-2` (stacks on mobile, side-by-side from the `lg` breakpoint):
  - **To-Dos** card — `ListChecks` icon, `{count} open` on the right, `<ul>` of the snapshot items (truncated), or the empty-state text; `<Link href="/todos">` "View all to-dos".
  - **Recent bookmarks** card — `BookmarkIcon` header, `<ul>` of `<Link href={`/bookmarks/${id}`}>` rows each with a `Globe`/`Video` icon by `url_type` and a truncated title, or "No bookmarks saved yet."; `<Link href="/bookmarks">` "View all bookmarks".
- `<Head>` description / `og:description` updated from the placeholder "Your account home." to describe the snapshot.
- Uses only existing design-system tokens (`border-hairline`, `bg-page`, `text-ink-display`/`-body`/`-muted`, `text-accent`) and `lucide-react` icons already in the bundle.

### Build config — `vite.config.ts`
- `defineConfig({...})` → `defineConfig(({ command }) => ({...}))` so the config can branch on Vite's command.
- For **any** `vite build` (production build, `--ssr` bundle, and the per-env auto-builds `vite_ruby` runs for non-dev Rails envs such as `--mode test` for `bin/rails test:system`) it now injects `define: { 'process.env.NODE_ENV': JSON.stringify('production') }`.
- Why: without it, `vite build --mode test` leaves `NODE_ENV` as `"development"`, so React's **dev** build lands in the system-test bundle; its scheduler doesn't flush state updates under headless Chrome and every page renders but is non-interactive. This was surfaced while getting `test:system` green for this milestone.

### Tests — `test/controllers/dashboard_controller_test.rb` (new, 4 tests / 13 assertions)
- Unauthenticated → redirect to `login_path`.
- Authenticated → `200`.
- Open-to-dos snapshot counts **only the current user's** incomplete todos, excludes completed and another user's; `open_todos` descriptions come back in `created_at: :asc` order.
- Recent-bookmarks snapshot returns the current user's **five newest, newest-first**, excluding the 6th-oldest and another user's bookmark.
- Helper `inertia_props_for(path)` parses the `#app[data-page]` JSON out of the rendered HTML and returns the `props` hash (no new test infra, just Nokogiri which is already a dep).

## Verification

- `bin/rails test` — **123 runs, 331 assertions, 0 failures, 0 errors, 0 skips**.
- `bin/rails test:system` — **2 runs, 34 assertions, 0 failures** (`bookmarks_test`, `todos_test`).
- `bin/rubocop` — clean (88 files, 0 offenses).
- `npm run check` (`tsc` x2) — clean.
- **Live browser** (`PORT=3000 bin/dev`, logged in as the milestone verify user):
  - `/dashboard` renders "Home" + "Welcome back, Jeffrey Verify.", a **To-Dos** card showing "2 open" with "Task A" / "Task C", and a **Recent bookmarks** card showing "Example Domain", "My Own Custom Title (edited)", "Rick Astley – Never Gonna Give You Up (Official Video) (4K Remaster)" with the right website/video icons.
  - Cross-checked against the real pages: `/todos` shows exactly Task A + Task C open (Task B completed) → count of 2 is correct; `/bookmarks` shows exactly those 3 bookmarks newest-first → snapshot matches.
  - "View all to-dos →" navigates to `/todos`; "View all bookmarks →" navigates to `/bookmarks`.
  - Screenshot: `_build_plan/milestones/5-dashboard-and-deploy/verify.png`.
- **Mobile**: the Chrome screenshot tool in this environment captures at a fixed viewport, so the mobile layout was confirmed by inspection rather than a fresh screenshot — the snapshot grid is `grid-cols-1 lg:grid-cols-2` (single column below `lg`) and `MainNav` already ships the `lg:hidden` hamburger + slide-over drawer established and system-tested since milestone 1. No new fixed-width or overflow constructs were introduced.

## Decisions not pre-specified in the PRD

- **Snapshot size = 5** for both panels (`SNAPSHOT_LIMIT`). The PRD says "the next few" / "the few most recently saved"; 5 is the concrete number.
- **Open-to-dos count is the true total** (`open_todos_count`), shown separately from the capped list — so "12 open" can display above only 5 rows.
- **Open-to-dos order is `created_at: :asc`** to match the To-Dos page's open section, so "the next few" means the same thing in both places.
- **Greeting fallback chain** name → email local-part → "there" (no raw email in the greeting).
- **No dashboard system test** added — the props/scoping/ordering are covered by the new integration test and the flow was verified live, matching how milestone 4 handled its verification split. `test/system/` still holds just `bookmarks_test` + `todos_test`.
- **"Final visual/copy polish across the app"** (a PRD line item for this milestone): the dashboard was brought up to the design-system bar; no other page needed changes — milestones 1–4 already left the To-Dos, Bookmarks, Tags, and auth pages consistent. No app-wide restyle was undertaken.

## Deviations from the PRD, and why

- **The production deploy to Hatchbox was not performed.** It's outward-facing and potentially cost-incurring (a new Hatchbox app / server), so it was left as an explicit human step rather than run autonomously. Everything that does *not* require the deploy is complete and green.
- Because of that, the milestone's full "Done when" — *"The live production URL loads the app…"* — is **not** met yet. The rest of that criterion (*"a logged-in user sees an accurate open-to-dos count and recent bookmarks on the Home page, and both snapshots link to their full pages"*) **is** met and verified locally.
- Still outstanding for whoever runs the deploy:
  - Push `prd-build/2026-08-27` and deploy on Hatchbox.
  - Set `ANTHROPIC_API_KEY` and `RESEND_API_KEY` in the Hatchbox environment (they are gitignored, never committed).
  - Set the real `config.action_mailer.default_url_options[:host]` for production/staging (still the template default `"example.com"` — noted since milestone 4).
  - Point `ApplicationMailer` `from:` at a verified Resend domain (currently `no-reply@jeffreyapps.app`, unverified).
  - Verify the live URL loads and the dashboard snapshots render for a real logged-in user.

## What a follow-up needs to know

- No new models, migrations, routes, or gems in this milestone — it's a controller + one page + a build-config tweak.
- `DashboardController#show` is the only place the snapshots are assembled; extending them (e.g. showing `summary_status` on the bookmark rows, which is already on `Bookmark`) is a localized change there + in `Dashboard.tsx`.
- The `vite.config.ts` `command === 'build'` branch is load-bearing for `bin/rails test:system` — don't drop it when touching that file.
