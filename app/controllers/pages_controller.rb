# frozen_string_literal: true

class PagesController < ApplicationController
  allow_unauthenticated_access only: :home

  # Portfolio content for the public home page. Edit these lists when the
  # apps, repos, or sites change -- they are not fetched from GitHub at runtime.
  WEB_APPS = [
    {
      name: "Bookmarks",
      description: "Save any link and get an automatic AI summary of the page. Organize with tags, filter your list, and share a bookmark by email.",
      href: "/login"
    },
    {
      name: "To-Dos",
      description: "A fast, low-friction task list. Add, complete, and re-open items, with finished tasks tucked below the ones still open.",
      href: "/login"
    }
  ].freeze

  SKILL_REPOS = [
    {
      name: "hindsight",
      description: "A self-improvement skill for AI coding assistants -- reviews a session end-to-end and saves only the durable process lessons as persistent memory.",
      href: "https://github.com/EfficientStreet/hindsight"
    },
    {
      name: "website-building-skill",
      description: "Based on Nate Herk's Awesome Website Builder Skill at AI Automation Society, with additional pre- and post-production prompts to dive deeper into website design.",
      href: "https://github.com/EfficientStreet/website-building-skill"
    },
    {
      name: "youtube-subscriptions-ingest",
      description: "Pulls YouTube subscription metadata into a real cross-linked knowledge graph in your second-brain vault.",
      href: "https://github.com/EfficientStreet/youtube-subscriptions-ingest"
    }
  ].freeze

  WEBSITES = [
    {
      name: "efficientstreet.com",
      description: "The site for Efficient Street, a digital efficiency studio that streamlines businesses through automation, integration, and marketing. Tagline: \"Automate. Integrate. Elevate.\"",
      href: "https://efficientstreet.com"
    }
  ].freeze

  def home
    return redirect_to(dashboard_path) if authenticated?

    render inertia: "Home", props: {
      web_apps: WEB_APPS,
      skill_repos: SKILL_REPOS,
      websites: WEBSITES
    }
  end
end
