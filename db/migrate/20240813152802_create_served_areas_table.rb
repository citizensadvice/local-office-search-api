# frozen_string_literal: true

class CreateServedAreasTable < ActiveRecord::Migration[7.1]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :served_areas do |t|
      t.references :office, null: false, foreign_key: true, type: "char(18)"
      t.references :local_authority, null: false, index: true, type: "char(9)"
    end
    add_foreign_key :served_areas, :local_authorities, deferrable: true
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
