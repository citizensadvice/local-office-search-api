# frozen_string_literal: true

module LssLoader
  module Validators
    def validate_csv_headers!
      raise LssLoadError, "Members CSV file was not in expected format" unless members_csv_has_expected_headers?
      raise LssLoadError, "Advice Locations CSV file was not in expected format" unless advice_locations_csv_has_expected_headers?
      raise LssLoadError, "Opening Hours CSV file was not in expected format" unless opening_hours_csv_has_expected_headers?
      raise LssLoadError, "Volunteer roles CSV file was not in expected format" unless volunteer_roles_csv_has_expected_headers?
      raise LssLoadError, "Accessibility info CSV file was not in expected format" unless accessibility_info_csv_has_expected_headers?
    end

    private

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
        salesforce_advice_location_id advice_location_name location_type_name salesforce_parent_id
        street_name city county postcode latitude longitude phone public_website last_modified_date
        allows_drop_in_visits enquiries_email emergency_contact_email excluded_from_lss_front_end has_referral_service
        resource_directory_id service_notes is_location_closed membership_number advice_service_information
        government_region currently_recruiting_volunteers face_to_face_advice_hours_information telephone_advice_hours_information
        excluded_from_lss_reports closed_from reopened_from location_status volunteer_recruitment_email
        local_authority_ons_name local_authority_ons_code location_type_id
      ]
    end

    def opening_hours_csv_has_expected_headers?
      @opening_hours_csv.headers == %w[advice_location_salesforce_id session_day session_start_time session_end_time session_type]
    end

    def volunteer_roles_csv_has_expected_headers?
      @volunteer_roles_csv.headers == %w[salesforce_advice_location_id advice_location_volunteer_roles_recruiting_status]
    end

    def accessibility_info_csv_has_expected_headers?
      @accessibility_info_csv.headers == %w[salesforce_advice_location_id advice_location_accessibility]
    end
  end
end
