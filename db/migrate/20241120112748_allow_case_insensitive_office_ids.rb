# frozen_string_literal: true

class AllowCaseInsensitiveOfficeIds < ActiveRecord::Migration[7.2]
  def change
    add_index(:offices, "lower(id)", unique: true)
  end
end
