require "test_helper"

class ShareMailerTest < ActionMailer::TestCase
  test "share sets recipient, subject, and includes the body" do
    bookmark = bookmarks(:rails_guides)

    mail = ShareMailer.share(
      bookmark,
      to: "friend@example.com",
      subject: "Check out: Ruby on Rails Guides",
      body: "Thought you'd like this.\n\nhttps://guides.rubyonrails.org"
    )

    assert_equal [ "friend@example.com" ], mail.to
    assert_equal "Check out: Ruby on Rails Guides", mail.subject
    assert_match "Thought you'd like this.", mail.text_part.body.to_s
    assert_match "https://guides.rubyonrails.org", mail.text_part.body.to_s
    assert_match "Thought you", mail.html_part.body.to_s
    assert_match "https://guides.rubyonrails.org", mail.html_part.body.to_s
  end
end
