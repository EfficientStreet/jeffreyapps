class GrantAdminToJeffrey < ActiveRecord::Migration[8.0]
  # Standalone AR class so this data migration keeps working regardless of
  # future changes to the User model (validations, callbacks, has_secure_password).
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  ADMIN_EMAIL = "jeffrey@efficientstreet.com".freeze

  def up
    MigrationUser.where(email: ADMIN_EMAIL).update_all(admin: true)
  end

  def down
    MigrationUser.where(email: ADMIN_EMAIL).update_all(admin: false)
  end
end
