require "test_helper"

# Chrome's legacy headless mode reports `document.hasFocus() === false`, which
# stops Selenium click-to-focus from landing on form fields (typing then goes
# nowhere). Chrome's "new" headless mode runs a real browser with a virtual
# display and does not have this problem, so register a driver that uses it.
Capybara.register_driver :headless_chrome_new do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--window-size=1400,1400")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper

  driven_by :headless_chrome_new, screen_size: [ 1400, 1400 ]

  private
    # Type into a controlled React input reliably.
    #
    # `fill_in`'s bulk value-set can land before the input's onChange handler is
    # wired (right after Inertia hydration or a modal mount), so the first render
    # wipes it. Under `--headless=new` a plain `fill_in` can also silently miss
    # if focus never landed on the freshly mounted element. So: re-resolve the
    # field each attempt, click it to force focus, clear it, then type
    # character-by-character with `send_keys` (which routes through the real key
    # event pipeline React listens on). Retry until the value sticks.
    def fill_in_hydrated(locator, with:)
      value = with
      10.times do |i|
        sleep 0.2 unless i.zero?
        field = find_field(locator)
        field.click
        field.set("") unless field.value.to_s.empty?
        field.send_keys(value)
        return if field.value == value
      end
      assert_field locator, with: value
    end
end
