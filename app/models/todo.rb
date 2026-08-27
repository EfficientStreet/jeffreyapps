class Todo < ApplicationRecord
  belongs_to :user

  validates :description, presence: true, length: { maximum: 500 }

  scope :ordered, -> { order(completed: :asc, created_at: :asc) }
end
