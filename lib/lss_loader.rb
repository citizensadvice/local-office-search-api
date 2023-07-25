# frozen_string_literal: true

require "csv"
require "csv_helpers"
require "lss_loader/office_builder"

module LssLoader
  class LssLoader
    include CsvHelpers
    include OfficeBuilder

    def initialize(members_csv, advice_locations_csv, opening_hours_csv)
      @members_csv = CSV.new members_csv, headers: true, return_headers: true
      @advice_locations_csv = CSV.new advice_locations_csv, headers: true, return_headers: true
      @opening_hours_csv = CSV.new opening_hours_csv, headers: true, return_headers: true
      initialise_csv_headers!
    end

    def load!
      ActiveRecord::Base.transaction do
        validate_csv_headers!
        Office.delete_all
        save_offices_by_tier! build_office_records
      end
    end

    private

    def initialise_csv_headers!
      @members_csv.shift if @members_csv.headers == true
      @advice_locations_csv.shift if @advice_locations_csv.headers == true
      @opening_hours_csv.shift if @opening_hours_csv.headers == true
    end

    def validate_csv_headers!
      raise LssLoadError, "Members CSV file was not in expected format" unless members_csv_has_expected_headers?
      raise LssLoadError, "Advice Locations CSV file was not in expected format" unless advice_locations_csv_has_expected_headers?
      raise LssLoadError, "Opening Hours CSV file was not in expected format" unless opening_hours_csv_has_expected_headers?
    end

    def members_csv_has_expected_headers?
      @members_csv.headers == %w[
        salesforce_id location_type_id salesforce_parent_id street_name city latitude longitude public_website
        last_modified_date excluded_from_lss_front_end membership_number charity_number company_number membership_end_date
        government_region membership_status member_short_name membership_start_date local_authority_ons_name resource_directory_id
        enquiries_email member_full_name county postcode local_authority_ons_code
      ]
    end

    def advice_locations_csv_has_expected_headers?
      @advice_locations_csv.headers == %w[
        salesforce_id advice_location_name salesforce_parent_id resource_directory_id location_type_id
        advice_service_information accessiblity_details street_name city postcode latitude longitude email website phone
        closed_from reopened_from currently_recruiting_volunteers volunteer_roles_currently_available volunteer_recruitment_email
        membership_number face_to_face_advice_hours_information telephone_advice_hours_information location_status
      ]
    end

    def opening_hours_csv_has_expected_headers?
      @opening_hours_csv.headers == %w[advice_location_salesforce_id session_day session_start_time session_end_time session_type]
    end

    def build_office_records
      offices = {}
      build_office_records_from_members_csv(offices)
      build_office_records_from_advice_locations_csv(offices)

      @opening_hours_csv.each do |row|
        apply_opening_hours! offices, row
      end

      nullify_dangling_parent_ids! offices
      offices
    end

    def build_office_records_from_members_csv(offices)
      @members_csv.each do |row|
        office = office_from_member_row row
        offices[office[:id]] = office
      end
    end

    def build_office_records_from_advice_locations_csv(offices)
      @advice_locations_csv.each do |row|
        next if row["salesforce_id"].nil?

        office = office_from_advice_location_row row
        offices[office[:id]] = office
      end
    end

    def nullify_dangling_parent_ids!(offices)
      orphaned_offices = offices.values.select { |office| !office.parent_id.nil? && !offices.key?(office.parent_id) }
      orphaned_offices.each do |office|
        office.parent_id = nil
      end
    end

    # because we can see offices in any order (e.g., outreach before the branch) we need to make
    # sure that the parent object already exists before we commit it. One way to do this is to
    # commit each layer of the hierarchy in order
    def save_offices_by_tier!(offices)
      tiers = offices.values.group_by(&:office_type)
      tiers.fetch("member", []).map(&:save!)
      tiers.fetch("office", []).map(&:save!)
      tiers.fetch("outreach", []).map(&:save!)
    end
  end

  class LssLoadError < StandardError
  end
end
