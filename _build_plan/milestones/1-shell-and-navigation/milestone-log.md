# Milestone 1 — Shell & navigation

## What's new in the app

- The app is now branded **JeffreyApps** — in the sidebar, the browser tab, and the public landing page.
- The public landing page (`/`) now says what JeffreyApps is ("Your to-dos and bookmarks in one place.") instead of the starter "Hello world" placeholder, and keeps the Sign up / Log in buttons.
- The left sidebar now has **three destinations**: Home, To-Dos, and Bookmarks. The one you're on is highlighted.
- **To-Dos** (`/todos`) and **Bookmarks** (`/bookmarks`) are real, reachable pages once you're logged in — each shows a titled placeholder ("Your to-dos will live here." / "Your bookmarks will live here.") ready to be filled in by later milestones.
- The sidebar still collapses to an icon rail and **remembers whether it was collapsed** the next time you visit. On a phone it still opens as a hamburger slide-over.
- Your profile now has an optional **Name** field ("My details" tab under Profile). Setting it shows a "Name updated." confirmation and the value sticks.

## What was built

### Branding
- `app/frontend/components/MainNav.tsx` — `BRAND` changed `"Build New"` → `"JeffreyApps"`; added `Bookmark` and `ListTodo` to the lucide import.
- `app/views/layouts/application.html.erb` — default `<title>` fallback and `apple-mobile-web-app-title` changed to `"JeffreyApps"`.
- `app/views/pwa/manifest.json.erb` — `name` → `"JeffreyApps"`, `description` → `"Your to-dos and bookmarks in one place."` (the PWA manifest route is still commented out in the template, but the strings are now correct if it's enabled).
- `app/javascript/pages/Home.tsx` — replaced hero copy with `<h1>JeffreyApps</h1>` + `<p>Your to-dos and bookmarks in one place.</p>`; updated all four `<Head>` tags (title, description, og:title, og:description). Sign up / Log in buttons unchanged.

### Navigation
- `MainNav.tsx` `DEFAULT_NAV_ITEMS` now has exactly three entries:
  - Home → `/dashboard`, icon `Home`, matches `url === "/" || url.startsWith("/dashboard")`
  - To-Dos → `/todos`, icon `ListTodo`, matches `url.startsWith("/todos")`
  - Bookmarks → `/bookmarks`, icon `Bookmark`, matches `url.startsWith("/bookmarks")`
- All the sidebar mechanics (desktop collapse + `localStorage` persistence under key `main-nav-open`, mobile hamburger + slide-over, active-item highlight, bottom user menu) are the template's existing implementation — unchanged apart from the brand string and the item list. Verified still working in the browser.

### Placeholder feature pages
- Routes added to `config/routes.rb` right after `dashboard` / `settings`:
  ```ruby
  resources :todos,     only: %i[ index ]
  resources :bookmarks, only: %i[ index ]
  ```
- `app/controllers/todos_controller.rb` — `TodosController#index` → `render inertia: "Todos"`.
- `app/controllers/bookmarks_controller.rb` — `BookmarksController#index` → `render inertia: "bookmarks/Index"`.
- Both inherit `ApplicationController`; the `Authentication` concern's `before_action :require_authentication` makes auth the default, so both pages redirect to `/login` when signed out (verified by test + browser).
- `app/javascript/pages/Todos.tsx` — `<AppShell>` + full `<Head>` (4 tags) + `<h1>To-Dos</h1>` + `<p>Your to-dos will live here.</p>`.
- `app/javascript/pages/bookmarks/Index.tsx` — same shape, "Bookmarks" / "Your bookmarks will live here." Default export named `BookmarksIndex`.

### User `name` field (see Deviations)
- Migration `db/migrate/20260827000001_add_name_to_users.rb` — `add_column :users, :name, :string` (nullable, no default). `db/schema.rb` version bumped to `2026_08_27_000001`.
- `app/models/user.rb` — `normalizes :name, with: ->(n) { n.strip }` and `validates :name, length: { maximum: 100 }, allow_blank: true`. Name is optional.
- `app/controllers/application_controller.rb` — `inertia_share` `current_user` hash now includes `name: Current.user.name`.
- `app/frontend/types/inertia.ts` — `CurrentUser` type gains `name: string | null`.
- `config/routes.rb` — `patch "profile/name", to: "profiles#update_name"` (added just before `profile/email`).
- `app/controllers/profiles_controller.rb` — `#update_name`: `Current.user.update(params.permit(:name))` → `redirect_to profile_path, notice: "Name updated."` on success, `redirect_to profile_path, inertia: { errors: ... }` on failure. Ported verbatim from simple-todos.
- `app/javascript/pages/profile/Details.tsx` — added a Name `<form>` (via `useForm({ name: user?.name ?? "" })`, `nameForm.patch("/profile/name")`) above the existing email form. Copied from simple-todos' `Details.tsx`.
- `_build_plan/prd.html` — added a `name` row to the **User** entity card's table (only change to the PRD).

### Crawler files
- `public/robots.txt` — added `Disallow: /todos` and `Disallow: /bookmarks` (new auth-gated prefixes), per the AGENTS.md convention. `config/sitemap.rb` and `public/llms.txt` untouched — Home is already covered and no old hero copy/title is referenced there.

### Tests
- `test/integration/ssr_smoke_test.rb` — the Home-page body assertion updated from `"Hello world"` to `"Your to-dos and bookmarks in one place"` (intentional copy change; test not weakened).
- `test/fixtures/users.yml` — `name:` added to fixtures `one` ("Jamie One") and `two` ("Jordan Two").
- `test/controllers/profiles_controller_test.rb` — new. Auth'd PATCH `/profile/name`: updates + redirects; strips whitespace; blank allowed; >100 chars rejected (name unchanged); unauthenticated redirects to login.
- `test/controllers/todos_controller_test.rb`, `test/controllers/bookmarks_controller_test.rb` — new. Each: redirects to login when signed out; `:success` when signed in.

## Decisions made during implementation (not pre-specified)

- **PWA manifest strings** (`app/views/pwa/manifest.json.erb`) were rebranded to JeffreyApps even though the manifest route is commented out in the template — cheap correctness, no runtime effect. `theme_color`/`background_color` (`"red"`) left as-is; out of scope.
- **`robots.txt`** gained `Disallow` lines for `/todos` and `/bookmarks` — follows the AGENTS.md rule for new auth-gated route prefixes.
- **Placeholder page style**: bare `<h1>` + `<p className="mt-2">` (matching the existing `Settings.tsx`), not `<PageHeader>`. The locked decision allowed either; `Settings.tsx` is the closest sibling inner page and uses the bare form.
- **`bookmarks/Index.tsx` default export** named `BookmarksIndex` (Settings-style naming), component name only — does not affect Inertia resolution.
- **Fixture names**: `one` and `two` got names; `admin` deliberately left nameless to keep a no-name user in the fixtures for coverage.
- **Dashboard.tsx**: left exactly as-is (still `<Head title="Home">`, "Welcome to your account, {email}."). It didn't read as template-ish and milestone 5 owns its content.

## What the next milestone needs to know

- **`resources :todos` and `resources :bookmarks` are `only: [:index]`** — milestone 2 must widen `:todos` (create/update/destroy etc.), milestone 3 must widen `:bookmarks` (+ add the Tags page/link from the Bookmarks page; Tags intentionally has **no** sidebar item).
- **Page component paths**: `app/javascript/pages/Todos.tsx` (Inertia name `"Todos"`) and `app/javascript/pages/bookmarks/Index.tsx` (Inertia name `"bookmarks/Index"`). Both are placeholders to be replaced with real UI. `TodosController` / `BookmarksController` currently render with no props.
- **`current_user` now carries `name`** (`ApplicationController#inertia_share` + `CurrentUser` type) — available on every page for milestone 5's personalized Home greeting. It can be `null`.
- **`User#name`** is optional, normalized (stripped), max 100 chars. Editable at Profile → My details via `PATCH /profile/name`.
- Sidebar collapse state key is `localStorage["main-nav-open"]` (`"true"` / `"false"`); brand constant is `BRAND` in `MainNav.tsx`.
- SSR smoke test asserts the string `"Your to-dos and bookmarks in one place"` appears in the rendered Home body — keep that phrase on `Home.tsx` (milestone 5's landing-page polish) or update the assertion in the same commit.
- `npm ci` / `npm install` was required on this checkout (empty `node_modules`); `bin/rails db:prepare` created `jeffreyapps_development` / `jeffreyapps_test`.

## Deviations from the PRD and why

- **Added `User#name`** (PRD's User entity was email + password only). This is an approved expansion: both source apps (simple-todos, bookmarker) have it, and milestone 5 needs it for the personalized greeting on the Home page. Folded into this milestone because it's template/auth-adjacent (migration + model + `inertia_share` + Profile form, all ported verbatim from simple-todos). `_build_plan/prd.html`'s User entity card was updated with a `name` row to keep the PRD in sync; nothing else in the PRD changed.
- No other deviations. No real to-do/bookmark functionality, dashboard snapshot, tags, AI summaries, sharing, or deployment work was done (all out of scope for milestone 1).
