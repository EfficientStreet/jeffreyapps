class TagsController < ApplicationController
  def index
    tags = Current.user.tags.includes(:bookmarks).order(:name)
    render inertia: "tags/Index", props: {
      tags: tags.map { |tag| { id: tag.id, name: tag.name, bookmarks_count: tag.bookmarks.size } }
    }
  end

  def update
    tag = Current.user.tags.find(params[:id])
    if tag.update(tag_params)
      redirect_to tags_path, notice: "Tag renamed."
    else
      redirect_back fallback_location: tags_path,
                    inertia: { errors: tag.errors.to_hash(true).transform_values(&:first) }
    end
  end

  def destroy
    tag = Current.user.tags.find(params[:id])
    tag.destroy
    redirect_to tags_path, notice: "Tag deleted."
  end

  def merge
    source = Current.user.tags.find(params[:id])
    target = Current.user.tags.find_by(id: params[:target_tag_id])

    if target.nil?
      return redirect_to tags_path, inertia: { errors: { target_tag_id: "must be a valid tag" } }
    end
    if target.id == source.id
      return redirect_to tags_path, inertia: { errors: { target_tag_id: "cannot merge a tag into itself" } }
    end

    ActiveRecord::Base.transaction do
      # Bookmarks already tagged with BOTH source and target: drop the
      # source join row (repointing it would violate the unique index).
      conflicting_bookmark_ids = target.bookmarks.where(id: source.bookmarks.select(:id)).pluck(:id)
      source.bookmark_tags.where(bookmark_id: conflicting_bookmark_ids).delete_all
      # Everything else: repoint to the target tag.
      source.bookmark_tags.update_all(tag_id: target.id)
      source.destroy
    end

    redirect_to tags_path, notice: "Merged \"#{source.name}\" into \"#{target.name}\"."
  end

  private
    def tag_params = params.require(:tag).permit(:name)
end
