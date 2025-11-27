# frozen_string_literal: true

class AllowDeferrableOfficeForeignKeys < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :offices, :local_authorities
    add_foreign_key :offices, :local_authorities, deferrable: :immediate
    remove_foreign_key :offices, :offices, column: "parent_id"
    add_foreign_key :offices, :offices, deferrable: :immediate, column: "parent_id"
  end
end
