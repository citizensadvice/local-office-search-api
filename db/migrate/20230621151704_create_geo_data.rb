# frozen_string_literal: true

class CreateGeoData < ActiveRecord::Migration[7.0]
  def change
    # We remove and recreate this table every time to ensure that any removed local authorities are
    # cleared up, so the timestamps are not reliable as they'll always be the last import date,
    # rather than modelling anything about the underlying thing they represent
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :local_authorities, id: "char(9)" do |t|
      t.column :name, :text, null: false
    end

    create_table :postcodes do |t|
      t.column :canonical, :string, limit: 8, null: false
      t.virtual :normalised, type: :string, limit: 7, as: "lower(replace(canonical, ' ', ''))", stored: true
      t.column :location, :st_point, null: false
      t.references :local_authority, index: true, type: "char(9)", null: false
    end
    add_foreign_key :postcodes, :local_authorities, deferrable: true
    add_index :postcodes, :normalised, unique: true
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
