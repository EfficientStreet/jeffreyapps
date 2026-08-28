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
end
