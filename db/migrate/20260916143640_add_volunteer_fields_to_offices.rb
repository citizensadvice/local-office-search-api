# frozen_string_literal: true

class AddVolunteerFieldsToOffices < ActiveRecord::Migration[8.1]
  def change
    add_column :offices, :remote_only_roles_available, :boolean, default: false, null: false
    add_column :offices, :rosterfy_microsite_url, :text, null: true
  end
end
