# frozen_string_literal: true

class AddAdditionalLssFields < ActiveRecord::Migration[7.0]
  def change
    add_column :offices, :county, :text, null: true
    add_column :offices, :volunteer_recruitment_email, :text, null: true
    add_column :offices, :allows_drop_ins, :boolean, default: false, null: false
  end
end
