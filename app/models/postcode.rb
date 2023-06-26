# frozen_string_literal: true

class Postcode < ApplicationRecord
  belongs_to :local_authority

  def self.normalise_and_find(postcode)
    find_by normalised: postcode.gsub(" ", "").downcase
  end

  # this overrides the default Rails upsert because that doesn't know how to handle conflicts on
  # virtual columns
  def self.upsert(attrs)
    query = <<-SQL.squish
      INSERT INTO "#{table_name}" (canonical,location,local_authority_id)
      VALUES (:canonical, :location, :local_authority_id)
      ON CONFLICT (normalised) DO
      UPDATE SET location=:location, local_authority_id=:local_authority_id
    SQL
    ActiveRecord::Base.connection.execute ActiveRecord::Base.sanitize_sql_array [query, attrs]
  end
end
