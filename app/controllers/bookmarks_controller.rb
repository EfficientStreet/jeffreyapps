class BookmarksController < ApplicationController
  def index
    bookmarks = Current.user.bookmarks.includes(:tags).order(created_at: :desc)
    render inertia: "bookmarks/Index", props: {
      bookmarks: bookmarks.map { |bookmark| bookmark_json(bookmark) },
      tags: Current.user.tags.order(:name).map { |tag| tag_json(tag) }
    }
  end

  def show
    bookmark = Current.user.bookmarks.includes(:tags).find(params[:id])
    render inertia: "bookmarks/Show", props: {
      bookmark: bookmark_json(bookmark),
      all_tags: Current.user.tags.order(:name).map { |tag| tag_json(tag) }
    }
  end

  def create
    bookmark = Current.user.bookmarks.build(create_params)
    provided_title = params.dig(:bookmark, :title)
    # Placeholder so a bad-URL failure doesn't ALSO show a spurious
    # "title can't be blank" error alongside the real one.
    bookmark.title = provided_title.presence || bookmark.url.to_s

    if bookmark.url_valid_format?
      metadata = UrlMetadataFetcher.call(bookmark.url)
      bookmark.url_type = metadata.url_type
      # Respect a user-provided title; only auto-fill from the page when blank.
      bookmark.title = metadata.title if provided_title.blank?
    end

    sync_tag_names(bookmark, params.dig(:bookmark, :tag_names) || [])

    if bookmark.save
      redirect_to bookmarks_path, notice: "Bookmark added."
    else
      redirect_back fallback_location: bookmarks_path,
                    inertia: { errors: bookmark.errors.to_hash(true).transform_values(&:first) }
    end
  end

  def update
    bookmark = Current.user.bookmarks.find(params[:id])
    bookmark.assign_attributes(update_params)
    sync_tag_names(bookmark, params[:bookmark][:tag_names]) if params[:bookmark]&.key?(:tag_names)

    if bookmark.save
      redirect_to bookmark_path(bookmark), notice: "Bookmark updated."
    else
      redirect_back fallback_location: bookmark_path(bookmark),
                    inertia: { errors: bookmark.errors.to_hash(true).transform_values(&:first) }
    end
  end

  def destroy
    bookmark = Current.user.bookmarks.find(params[:id])
    bookmark.destroy
    redirect_to bookmarks_path, notice: "Bookmark deleted."
  end

  private
    def create_params = params.require(:bookmark).permit(:url, :title, :notes)
    def update_params = params.require(:bookmark).permit(:title, :notes)

    # Case-insensitive find-or-create so tagging with "Ruby" reuses an
    # existing "ruby" tag rather than colliding with the case-insensitive
    # uniqueness index and raising.
    def sync_tag_names(bookmark, names)
      cleaned = Array(names).map { |name| name.to_s.strip }.reject(&:blank?).uniq { |name| name.downcase }
      bookmark.tags = cleaned.map do |name|
        Current.user.tags.where("lower(name) = ?", name.downcase).first ||
          Current.user.tags.create!(name: name)
      end
    end

    def bookmark_json(bookmark)
      {
        id: bookmark.id,
        url: bookmark.url,
        title: bookmark.title,
        url_type: bookmark.url_type,
        notes: bookmark.notes,
        summary: bookmark.summary,
        summary_status: bookmark.summary_status,
        created_at: bookmark.created_at.iso8601,
        updated_at: bookmark.updated_at.iso8601,
        tags: bookmark.tags.map { |tag| tag_json(tag) }
      }
    end

    def tag_json(tag) = { id: tag.id, name: tag.name }
end
