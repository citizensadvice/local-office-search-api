# frozen_string_literal: true

require "csv_helpers"
require "loader_helpers"

class PostcodeLoader
  include CsvHelpers
  include LoaderHelpers

  def initialize(postcode_csv)
    @postcode_csv = CSV.new postcode_csv, headers: true, return_headers: true
    initialise_csv_headers!
  end

  def load!
    ActiveRecord::Base.transaction do
      validate_csv_headers!
      defer_local_authority_integrity_checks_until_commit!
      LocalAuthority.delete_all
      local_authority_ids = create_postcodes_and_local_authorities!
      nullify_dangling_offices! local_authority_ids
    end
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_postcodes_and_local_authorities!
    # rubocop:disable Rails/SkipsModelValidations - we rely on database validations
    local_authorities = {}
    # do this in chunks for performance reasons
    @postcode_csv.each_slice(10_000) do |rows|
      rows.reject! { |row| row["local_authority_code"].nil? || row["local_authority_name"].nil? }
      rows.each do |row|
        local_authorities[row["local_authority_code"]] = row["local_authority_name"]
      end

      Postcode.bulk_upsert(rows.map { |row| postcode_attrs_from_row(row) })
    end
    LocalAuthority.insert_all(local_authorities.map { |id, name| { id:, name: } })
    # rubocop:enable Rails/SkipsModelValidations
    local_authorities.keys
  end
  # rubocop:enable Metrics/AbcSize

  def postcode_attrs_from_row(row)
    { canonical: row["postcode"], local_authority_id: row["local_authority_code"], location: point_wkt_or_nil(row["lat"], row["lon"]) }
  end

  def initialise_csv_headers!
    @postcode_csv.shift if @postcode_csv.headers == true
  end

  def validate_csv_headers!
    raise PostcodeLoadError, "Postcodes CSV file was not in expected format" unless postcode_csv_has_expected_headers?
  end

  def defer_local_authority_integrity_checks_until_commit!
    postcode_local_authority_foreign_key = "fk_rails_7ab3384eab"
    office_local_authority_foreign_key = "fk_rails_5a2ab5b59d"
    defer_constraint_until_commit! postcode_local_authority_foreign_key
    defer_constraint_until_commit! office_local_authority_foreign_key
  end

  def nullify_dangling_offices!(current_local_authority_ids)
    # rubocop:disable Rails/SkipsModelValidations - we rely on database validations
    Office.where.not(local_authority_id: current_local_authority_ids).update_all(local_authority_id: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def postcode_csv_has_expected_headers?
    @postcode_csv.headers == [
      nil, "postcode", "postcode_no_space", "postcode_area", "postcode_district", "date_start", "date_end", "state", "onspd_version",
      "easting", "northing", "positional_quality", "lat", "lon", "european_economic_region_code", "european_economic_region_name",
      "county_code", "county_name", "local_authority_code", "local_authority_name", "ward_code", "ward_name",
      "county_electoral_division_code", "county_electoral_division_name", "parish_code", "parish_name",
      "parliamentary_constituency_code", "parliamentary_constituency_name", "census_output_area_2021_code",
      "lower_super_output_area_2021_code", "lower_super_output_area_2021_name", "middle_super_output_area_2021_code",
      "middle_super_output_area_2021_name", "census_output_area_2011_code", "lower_super_output_area_2011_code",
      "rural_urban_area_2011_code", "imd_rank", "primary_care_trust_code", "integrated_care_board_subdivision_code",
      "integrated_care_board_subdivision_name", "police_force_area_code", "police_force_area_name", "integrated_care_board_code",
      "integrated_care_board_name", "westminster_member_of_parliament_code", "westminster_member_of_parliament",
      "westminster_political_party_code", "westminster_political_party"
    ]
  end

  class PostcodeLoadError < StandardError
  end
end
