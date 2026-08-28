class ShareMailer < ApplicationMailer
  def share(bookmark, to:, subject:, body:)
    @bookmark = bookmark
    @body = body
    mail subject: subject, to: to
  end
end
