class BookmarkTag < ApplicationRecord
  belongs_to :bookmark
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :bookmark_id }
  validate :tag_and_bookmark_belong_to_same_user

  private
    def tag_and_bookmark_belong_to_same_user
      return if bookmark.nil? || tag.nil?
      errors.add(:tag, "must belong to the same user as the bookmark") if bookmark.user_id != tag.user_id
    end
end
