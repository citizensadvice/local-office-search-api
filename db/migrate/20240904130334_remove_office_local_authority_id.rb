# frozen_string_literal: true

class RemoveOfficeLocalAuthorityId < ActiveRecord::Migration[7.1]
  def change
    remove_column :offices, :local_authority_id, index: true, type: "char(9)", null: false, references: :local_authority
  end
end
