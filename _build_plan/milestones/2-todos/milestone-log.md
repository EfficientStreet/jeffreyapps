# Milestone 2 — To-Dos

## What's new in the app

- **A working To-Dos page** at `/todos` that lists all of your to-dos, newest concerns first.
- **Add a to-do** by typing in the text box at the top and pressing Enter or clicking "Add".
- **Check a to-do off** with its checkbox — completed items drop into a separate "Completed" section and show with a line through them.
- **Uncheck** a completed item to send it back up to the active list.
- **Edit a to-do's wording** by clicking its text, typing, and pressing Enter (Escape cancels, clicking away also saves).
- **Delete a to-do** with the trash icon on its row.
- **Automatic ordering:** unfinished to-dos always sit above finished ones, and within each group the oldest appear first.
- **Friendly empty state:** when you have no active to-dos the page says "Nothing to do. Add a to-do above."
- The heading greets you by name — "Jamie One's To-Dos" (falls back to the name part of your email, or plain "To-Dos").

## What was built

### Data model
- `app/models/todo.rb` — `Todo` belongs to `User`; `description` required and ≤ 500 chars; `completed` boolean; `scope :ordered` → `order(completed: :asc, created_at: :asc)`.
- `app/models/user.rb` — added `has_many :todos, dependent: :destroy`.

### Migration / schema
- `db/migrate/20260827000002_create_todos.rb` — `todos` table: `user` reference (not null, FK), `description` string (not null), `completed` boolean (not null, default false), timestamps, plus a `[:user_id, :created_at]` index. Migrated; `db/schema.rb` version bumped to `2026_08_27_000002`.

### Routes
- `config/routes.rb` — widened `resources :todos` from `only: %i[ index ]` to `only: %i[ index create update destroy ]`.

### Controller
- `app/controllers/todos_controller.rb` — full port from simple-todos:
  - `index` renders `inertia: "Todos"` with `props: { todos: Current.user.todos.ordered.map { todo_json } }`.
  - `create` / `update` build/update on `Current.user.todos`; on success `redirect_to todos_path`, on failure `redirect_to todos_path, inertia: { errors: record.errors.to_hash(true).transform_values(&:first) }`.
  - `destroy` destroys and redirects.
  - `set_todo` scopes to `Current.user.todos.find(params[:id])` → another user's id raises `RecordNotFound` → 404.
  - `todo_params = params.permit(:description, :completed)`; `todo_json` = `{ id, description, completed, created_at: iso8601 }`.

### Frontend (Inertia + React)
- `app/frontend/components/TodoItem.tsx` — one row: `<Checkbox>` toggles `completed` via `router.patch`; click the text to inline-edit (Enter saves, Escape cancels, blur saves) via `router.patch`; ghost icon `<Button>` with `<Trash2>` deletes via `router.delete`. All requests `{ preserveScroll: true }`. Exports `type Todo`.
- `app/frontend/components/TodoList.tsx` — `useForm({ description: "" })`; `form.post("/todos", { preserveScroll: true, onSuccess: () => form.reset("description") })`. Splits `incomplete` / `completed`; renders the add form, a "To-Dos" section (empty-state text `"Nothing to do. Add a to-do above."`), and a "Completed" section only when there are completed items. Re-exports `type Todo`.
- `app/javascript/pages/Todos.tsx` — replaces the milestone-1 placeholder. Receives `{ todos }`, wraps in `<AppShell>`, sets `<Head title="To-Dos">` with description + `og:title` + `og:description` (description: "Your to-do list — add tasks, check them off, edit, and delete."). Heading `{displayName ? `${displayName}'s To-Dos` : "To-Dos"}` where `displayName` = capitalized `user?.name || user?.email.split("@")[0]`. Renders `<TodoList todos={todos} />`.

### Tests (all green)
- `test/fixtures/todos.yml` — `one_incomplete` ("Buy milk", user one, 1.day.ago), `one_completed` ("Walk the dog", user one, completed, 2.days.ago), `two_incomplete` ("Someone else's task", user two).
- `test/models/todo_test.rb` — validation (present / ≤500 / needs user), `ordered` puts incomplete first, destroying a user destroys their todos.
- `test/controllers/todos_controller_test.rb` — replaced the milestone-1 placeholder file with the full port: auth required for every action, create/update/edit/toggle/destroy happy paths (all assert `redirect` / `assert_redirected_to todos_path`), blank description does not create, another user's todo → `assert_response :not_found` for update and destroy. Local `log_in_as` helper posts to `login_path`.
- `test/system/todos_test.rb` — first system test in the repo. Logs in, navigates to `/todos`, creates "Buy milk", completes it (asserts it moves to "Completed" and renders `button.line-through`), inline-edits to "Buy oat milk", deletes it, asserts the empty state returns.
- `test/application_system_test_case.rb` — see "Decisions" below (custom headless-Chrome driver).

## Decisions not pre-specified in the PRD

1. **Inline-edit UX** (click text → input, Enter saves / Escape cancels / blur saves) and the **section sub-headings** (`<h2 class="text-sm font-semibold text-ink-display">To-Dos</h2>` / `Completed`) are carried over verbatim from the simple-todos source app for parity. The heading uses a curly apostrophe (`'s To-Dos`), also from source.
2. **`todo_json` shape** kept minimal (`id, description, completed, created_at`) — no `updated_at`, no user info — matching the source and milestone-2 needs.
3. **`params.permit` without `require`** (source-app style) — the Inertia client posts flat params (`{ description: ... }`), not wrapped in `todo[...]`.
4. **System-test infrastructure — custom headless-Chrome driver.** Chrome's legacy headless mode (what `driven_by :selenium, using: :headless_chrome` selects) reports `document.hasFocus() === false`, which prevented Selenium click-to-focus from landing on the new-to-do input, so typed text never registered and the test failed at the first `fill_in`. Fixed by registering a `:headless_chrome_new` Capybara driver that passes `--headless=new` (plus `--window-size=1400,1400`, `--no-sandbox`, `--disable-dev-shm-usage`, `--disable-gpu`) and pointing `driven_by` at it. With that, `fill_in` / clicks work and the system test passes. `ActiveJob::TestHelper` was **not** needed (no jobs in this milestone).
5. **System-test setup clears the user's fixture todos** (`@user.todos.destroy_all` in `setup`). The `users(:one)` fixture is seeded with a todo also named "Buy milk"; without clearing, `within("li", text: "Buy milk")` matched two rows. Clearing keeps the ported assertions (which use "Buy milk") intact and unambiguous. No assertion was weakened.
6. **Delete step in the system test** is followed by a positive `assert_text "Nothing to do. Add a to-do above."` before the `assert_no_selector` for the deleted row — a waiting assertion, per the known Inertia+Capybara async-POST race guidance.

## Anything the next milestone (3 — Bookmarks) needs to know

- **`resources :bookmarks` is still the milestone-1 placeholder: `only: %i[ index ]`.** Widen it the same way `todos` was widened here.
- `app/controllers/bookmarks_controller.rb` and `app/javascript/pages/Bookmarks.tsx` are still milestone-1 placeholders to be replaced.
- Pattern to reuse from this milestone: user-scoped `has_many` + `Current.user.<assoc>` in the controller, `redirect_to` (never `head`/`json`) from mutations with `inertia: { errors: ... }` on failure, `*_json` prop serializers, and the `TodoItem`/`TodoList` component split.
- **System tests now work** via the `:headless_chrome_new` driver in `test/application_system_test_case.rb` — new system tests just subclass `ApplicationSystemTestCase`.
- `db/schema.rb` is at version `2026_08_27_000002`; the next migration timestamp must be after that.

## Deviations from the PRD

None of substance. The To-Do model, fields, ordering, empty state, and all "Done when" behaviours (add / edit / complete / uncheck / delete, incomplete always above completed) are implemented as specified. The only additions beyond the PRD text are test-infrastructure choices (items 4–6 above), not product behaviour.
