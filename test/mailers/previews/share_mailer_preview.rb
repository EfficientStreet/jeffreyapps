# Preview all emails at http://localhost:3000/rails/mailers/share_mailer
class ShareMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/share_mailer/share
  def share
    bookmark = Bookmark.take
    ShareMailer.share(
      bookmark,
      to: "friend@example.com",
      subject: "Check out: #{bookmark.title}",
      body: "Thought you'd find this useful.\n\n#{bookmark.summary}\n\n#{bookmark.url}"
    )
  end
end
