# frozen_string_literal: true

class AddVolunteerRolesToOffices < ActiveRecord::Migration[7.0]
  def change
    add_column :offices, :volunteer_roles, :text, array: true, null: false, default: []
  end
end
