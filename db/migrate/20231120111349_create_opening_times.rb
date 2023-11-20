class CreateOpeningTimes < ActiveRecord::Migration[7.0]
  def change
    create_enum :opening_time_for_type, %w[office telephone]
    create_enum :day_of_week, %w[monday tuesday wednesday thursday friday saturday sunday]

    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :opening_times do |t|
      t.references :office, index: true, type: "char(18)", null: false, foreign_key: { to_table: :offices }
      t.column :opening_time_for, :opening_time_for_type, null: false
      t.column :day_of_week, :day_of_week, null: false
      t.column :range, :timerange, null: false
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
