require "application_system_test_case"

class BookmarksTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    # Fixtures seed this user with bookmarks/tags; clear them so this test's
    # own bookmark and tags are unambiguous.
    @user.bookmarks.destroy_all
    @user.tags.destroy_all

    # UrlMetadataFetcher runs synchronously on create; stub the page fetch so
    # the title auto-fills deterministically instead of hitting the network.
    stub_request(:get, "https://example.com/").to_return(
      status: 200, body: "<html><head><title>Example Domain</title></head></html>"
    )
  end

  test "add, view, edit, tag, filter, and delete a bookmark, then rename a tag" do
    visit "/login"
    fill_in "Email", with: @user.email
    fill_in "Password", with: "password"
    click_button "Log in"
    # The Inertia login POST is async; wait for the redirect before navigating.
    assert_selector "h1", text: "Home"

    visit "/bookmarks"
    assert_text "You haven’t added any bookmarks yet"

    # --- Add a bookmark with no title: title auto-fills from the page ---
    open_modal_via "Add your first bookmark"
    within(".modal") do
      set_controlled_field "URL", "https://example.com"
      click_button "Add bookmark"
    end
    assert_text "Bookmark added."
    assert_text "Example Domain"
    assert_text "Website"

    # --- Detail view: neutral summary placeholder, no regenerate/share ---
    click_link "Example Domain"
    assert_text "AI summary"
    assert_text "Summaries aren’t available yet."
    assert_no_text "Regenerate"
    assert_no_text "Share"

    # --- Edit title + notes ---
    open_modal_via "Edit"
    within(".modal") do
      set_controlled_field "Title", "Example Domain (edited)"
      set_controlled_field "Notes", "some notes"
      click_button "Save changes"
    end
    assert_text "Bookmark updated."
    assert_text "Example Domain (edited)"

    # Persisted across a reload
    refresh
    assert_text "Example Domain (edited)"
    assert_text "some notes"

    # --- Tag it from the detail view ---
    tag_field = find("#bookmark-tags-show")
    tag_field.set("Cooking")
    tag_field.send_keys(:enter)
    assert_text "Cooking"

    # --- Filter the list by that tag ---
    click_link "Back to bookmarks"
    assert_text "Example Domain (edited)"
    # Wait for hydration, then click the tag-filter chip until it registers.
    click_button "Cooking"
    unless has_button?("Clear filter", wait: 2)
      5.times do
        sleep 0.3
        click_button "Cooking"
        break if has_button?("Clear filter", wait: 1)
      end
    end
    assert_button "Clear filter"
    assert_text "Example Domain (edited)"
    click_button "Clear filter"
    assert_no_button "Clear filter"

    # --- Rename the tag from the Tags page ---
    click_link "Manage tags"
    assert_selector "h1", text: "Tags"
    assert_text "Cooking"
    find("button[aria-label='Actions for Cooking']").click
    find("[role='menuitem']", text: "Rename").click
    within(".modal") do
      set_controlled_field "Name", "Recipes"
      click_button "Rename"
    end
    assert_text "Tag renamed."
    assert_text "Recipes"

    # --- Delete the bookmark ---
    click_link "Back to bookmarks"
    click_link "Example Domain (edited)"
    open_modal_via "Delete"
    within(".modal") do
      click_button "Delete"
    end
    assert_text "Bookmark deleted."
    assert_no_text "Example Domain (edited)"
  end

  private
    # A button click right after SSR markup appears but before React hydrates is
    # a no-op. Click the trigger and wait for the Radix dialog (".modal"); retry
    # the click until it opens.
    def open_modal_via(button_text)
      click_button button_text
      return if has_selector?(".modal", wait: 2)

      10.times do
        sleep 0.3
        click_button button_text
        break if has_selector?(".modal", wait: 1)
      end
      assert_selector ".modal"
    end

    # Right after Inertia hydration a controlled React input can drop the first
    # keystrokes; re-fill until the value sticks.
    def set_controlled_field(locator, value)
      fill_in locator, with: value
      return if find_field(locator).value == value

      10.times do
        sleep 0.2
        fill_in locator, with: value
        break if find_field(locator).value == value
      end
      assert_field locator, with: value
    end
end
