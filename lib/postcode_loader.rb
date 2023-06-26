# frozen_string_literal: true

require "csv_helpers"

class PostcodeLoader
  include CsvHelpers

  def initialize(postcode_csv)
    @postcode_csv = CSV.open postcode_csv, headers: true, return_headers: true
    initialise_csv_headers!
  end

  def load!
    ActiveRecord::Base.transaction do
      validate_csv_headers!
      defer_local_authority_integrity_checks_until_commit!
      LocalAuthority.delete_all
      create_postcodes_and_local_authorities!
    end
  end

  private

  def create_postcodes_and_local_authorities!
    # rubocop:disable Rails/SkipsModelValidations - we rely on database validations
    local_authorities = {}
    @postcode_csv.each do |row|
      Postcode.upsert postcode_attrs_from_row(row)
      local_authorities[row["local_authority_code"]] = row["local_authority_name"]
    end
    LocalAuthority.insert_all(local_authorities.map { |id, name| { id:, name: } })
    # rubocop:enable Rails/SkipsModelValidations
  end

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
    ActiveRecord::Base.connection.execute("SET CONSTRAINTS fk_rails_7ab3384eab DEFERRED")
  end

  def postcode_csv_has_expected_headers?
    @postcode_csv.headers == %w[
      postcode postcode_no_space postcode_area postcode_district date_start date_end state onspd_version
      easting northing positional_quality lat lon european_economic_region_code european_economic_region_name
      county_code county_name local_authority_code local_authority_name ward_code ward_name
      county_electoral_division_code county_electoral_division_name parish_code parish_name
      parliamentary_constituency_code parliamentary_constituency_name census_output_area_2021_code
      lower_super_output_area_2021_code census_output_area_2011_code lower_super_output_area_2011_code
      rural_urban_area_2011_code imd_rank primary_care_trust_code integrated_care_board_subdivision_code
      integrated_care_board_subdivision_name police_force_area_code police_force_area_name integrated_care_board_code
      integrated_care_board_name westminster_member_of_parliment westminster_political_party
    ]
  end

  class PostcodeLoadError < StandardError
  end
end
