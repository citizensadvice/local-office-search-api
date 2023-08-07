# frozen_string_literal: true

class ConvertLocationToGeography < ActiveRecord::Migration[7.0]
  def up
    change_column :offices, :location, :st_point, geographic: true, null: true, srid: 4326
    change_column :postcodes, :location, :st_point, geographic: true, null: false, srid: 4326
  end

  def down
    change_column :offices, :location, :st_point, null: true
    change_column :postcodes, :location, :st_point, null: false
  end
end
