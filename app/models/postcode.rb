# frozen_string_literal: true

class Postcode < ApplicationRecord
  attribute :location, :st_point, srid: 4326, geographic: true
  belongs_to :local_authority

  def scottish?
    local_authority_id.start_with? "S"
  end

  def northern_irish?
    local_authority_id.start_with? "N"
  end

  def self.normalise_and_find(postcode)
    find_by normalised: postcode.gsub(" ", "").downcase
  end

  # this overrides the default Rails upsert because that doesn't know how to handle conflicts on
  # virtual columns
  def self.bulk_upsert(vals)
    ActiveRecord::Base.connection.execute <<-SQL.squish
      INSERT INTO "#{table_name}" (canonical,location,local_authority_id)
      VALUES #{vals.map { |attrs| ActiveRecord::Base.sanitize_sql_array ['(:canonical, :location, :local_authority_id)', attrs] }.join(',')}
      ON CONFLICT (normalised) DO
      UPDATE SET location=EXCLUDED.location, local_authority_id=EXCLUDED.local_authority_id
    SQL
  end
end
