# frozen_string_literal: true

class AddMoreIdentifiersToOffices < ActiveRecord::Migration[7.0]
  def change
    change_table :offices do |t|
      t.string :membership_number, null: true
      t.string :company_number, null: true
      t.string :charity_number, null: true
    end

    add_index :offices, %i[membership_number office_type]
    add_index :offices, :legacy_id
  end
end
