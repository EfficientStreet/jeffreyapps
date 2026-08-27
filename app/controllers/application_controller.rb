class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern

  inertia_share do
    {
      current_user: Current.user && {
        id: Current.user.id,
        email: Current.user.email,
        name: Current.user.name,
        timezone: Current.user.timezone,
        admin: Current.user.admin?
      },
      flash: {
        notice: flash.notice,
        alert: flash.alert
      }
    }
  end
end
