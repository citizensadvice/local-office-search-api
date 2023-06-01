### https://pganalyze.com/blog/custom-postgres-data-types-ruby-rails

class CreateOffices < ActiveRecord::Migration[7.0]
  def change
    enable_extension "postgis"

    # create a custom range type to hold opening hours, this isn't a native type
    # annoyingly, but is given as an example in the Postgres docs
    # https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-DEFINING
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE FUNCTION time_subtype_diff(x time, y time) RETURNS float8 AS 'SELECT EXTRACT(EPOCH FROM (x - y))' LANGUAGE sql STRICT IMMUTABLE;
          CREATE TYPE timerange AS RANGE ( subtype = time, subtype_diff = time_subtype_diff );
        SQL
      end
      dir.down do
        execute <<~SQL
          DROP TYPE timerange;
          DROP FUNCTION time_subtype_diff;
        SQL
      end
    end

    create_enum :office_type, %w[member office outreach]

    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :offices, id: "char(18)" do |t|
      # this corresponds to the Resource Directory ID to maintain URLs from the old system
      t.column :legacy_id, :integer, null: true
      t.column :office_type, :office_type, null: false
      t.references :parent, index: true, type: "char(18)", null: true, foreign_key: { to_table: :offices }
      t.column :name, :text, null: false
      t.column :about_text, :text, null: true
      t.column :accessibility_information, :text, array: true, null: false, default: []
      t.column :street, :text, null: true
      t.column :city, :text, null: true
      t.column :postcode, :text, null: true
      t.column :location, :st_point, null: true
      t.column :email, :text, null: true
      t.column :website, :text, null: true
      t.column :phone, :text, null: true
      t.column :opening_hours_information, :text, null: true
      t.column :opening_hours_monday, :timerange, null: false, default: "empty"
      t.column :opening_hours_tuesday, :timerange, null: false, default: "empty"
      t.column :opening_hours_wednesday, :timerange, null: false, default: "empty"
      t.column :opening_hours_thursday, :timerange, null: false, default: "empty"
      t.column :opening_hours_friday, :timerange, null: false, default: "empty"
      t.column :opening_hours_saturday, :timerange, null: false, default: "empty"
      t.column :opening_hours_sunday, :timerange, null: false, default: "empty"
      t.column :telephone_advice_hours_information, :text, null: true
      t.column :telephone_advice_hours_monday, :timerange, null: false, default: "empty"
      t.column :telephone_advice_hours_tuesday, :timerange, null: false, default: "empty"
      t.column :telephone_advice_hours_wednesday, :timerange, null: false, default: "empty"
      t.column :telephone_advice_hours_thursday, :timerange, null: false, default: "empty"
      t.column :telephone_advice_hours_friday, :timerange, null: false, default: "empty"
      t.column :telephone_advice_hours_saturday, :timerange, null: false, default: "empty"
      t.column :telephone_advice_hours_sunday, :timerange, null: false, default: "empty"
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
