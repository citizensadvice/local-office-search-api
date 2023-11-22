# frozen_string_literal: true

class RemoveLegacyOpeningTimeFields < ActiveRecord::Migration[7.0]
  def change
    remove_column :offices, :opening_hours_monday, :timerange, null: false, default: "empty"
    remove_column :offices, :opening_hours_tuesday, :timerange, null: false, default: "empty"
    remove_column :offices, :opening_hours_wednesday, :timerange, null: false, default: "empty"
    remove_column :offices, :opening_hours_thursday, :timerange, null: false, default: "empty"
    remove_column :offices, :opening_hours_friday, :timerange, null: false, default: "empty"
    remove_column :offices, :opening_hours_saturday, :timerange, null: false, default: "empty"
    remove_column :offices, :opening_hours_sunday, :timerange, null: false, default: "empty"
    remove_column :offices, :telephone_advice_hours_monday, :timerange, null: false, default: "empty"
    remove_column :offices, :telephone_advice_hours_tuesday, :timerange, null: false, default: "empty"
    remove_column :offices, :telephone_advice_hours_wednesday, :timerange, null: false, default: "empty"
    remove_column :offices, :telephone_advice_hours_thursday, :timerange, null: false, default: "empty"
    remove_column :offices, :telephone_advice_hours_friday, :timerange, null: false, default: "empty"
    remove_column :offices, :telephone_advice_hours_saturday, :timerange, null: false, default: "empty"
    remove_column :offices, :telephone_advice_hours_sunday, :timerange, null: false, default: "empty"
  end
end
