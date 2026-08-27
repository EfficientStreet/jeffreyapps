class Bookmark < ApplicationRecord
  belongs_to :user
  has_many :bookmark_tags, dependent: :destroy
  has_many :tags, through: :bookmark_tags

  enum :url_type, { website: "website", youtube: "youtube" }, validate: true
  enum :summary_status, { pending: "pending", completed: "completed", failed: "failed" }, validate: true

  YOUTUBE_HOSTS = %w[ youtube.com www.youtube.com m.youtube.com youtu.be ].freeze

  validates :url, presence: true
  validates :title, presence: true, length: { maximum: 500 }
  validates :notes, length: { maximum: 10_000 }, allow_blank: true
  validate :url_must_be_http_or_https

  def self.detect_url_type(url)
    host = URI.parse(url.to_s).host.to_s.downcase
    YOUTUBE_HOSTS.include?(host) ? "youtube" : "website"
  rescue URI::InvalidURIError
    "website"
  end

  def url_valid_format?
    uri = URI.parse(url.to_s)
    uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end

  private
    def url_must_be_http_or_https
      errors.add(:url, "must be a valid http:// or https:// address") unless url_valid_format?
    end
end
