# frozen_string_literal: true

module LssLoader
  module OfficeBuilder
    private

    # rubocop:disable Metrics/AbcSize
    def office_from_member_row(row)
      Office.new id: row["salesforce_id"],
                 name: row["member_full_name"],
                 office_type: record_type_id_to_office_type(row["location_type_id"]),
                 parent_id: str_or_nil(row["salesforce_parent_id"]),
                 legacy_id: str_or_nil(row["resource_directory_id"]),
                 membership_number: str_or_nil(row["membership_number"]),
                 charity_number: str_or_nil(row["charity_number"]),
                 company_number: str_or_nil(row["company_number"]),
                 street: str_or_nil(row["street_name"]),
                 city: str_or_nil(row["city"]),
                 county: str_or_nil(row["county"]),
                 postcode: str_or_nil(row["postcode"]),
                 location: point_wkt_or_nil(row["latitude"], row["longitude"]),
                 local_authority_id: str_or_nil(row["local_authority_ons_code"]),
                 email: str_or_nil(row["enquiries_email"]),
                 website: str_or_nil(row["public_website"])
    end

    def office_from_advice_location_row(row)
      Office.new id: row["salesforce_advice_location_id"],
                 name: row["advice_location_name"],
                 office_type: record_type_id_to_office_type(row["location_type_id"]),
                 parent_id: str_or_nil(row["salesforce_parent_id"]),
                 legacy_id: str_or_nil(row["resource_directory_id"]),
                 membership_number: str_or_nil(row["membership_number"]),
                 about_text: str_or_nil(row["advice_service_information"]),
                 street: str_or_nil(row["street_name"]),
                 city: str_or_nil(row["city"]),
                 county: str_or_nil(row["county"]),
                 postcode: str_or_nil(row["postcode"]),
                 location: point_wkt_or_nil(row["latitude"], row["longitude"]),
                 local_authority_id: str_or_nil(row["local_authority_ons_code"]),
                 email: str_or_nil(row["enquiries_email"]),
                 volunteer_recruitment_email: str_or_nil(row["volunteer_recruitment_email"]),
                 website: str_or_nil(row["public_website"]),
                 phone: str_or_nil(row["phone"]),
                 allows_drop_ins: bool_from_val(row["allows_drop_in_visits"]),
                 opening_hours_information: str_or_nil(row["face_to_face_advice_hours_information"]),
                 telephone_advice_hours_information: str_or_nil(row["telephone_advice_hours_information"])
    end
    # rubocop:enable Metrics/AbcSize

    def served_areas_from_member_row(row)
      served_areas = []
      served_areas << ServedArea.new(office_id: row["salesforce_id"], local_authority_id: str_or_nil(row["local_authority_ons_code"]))
      served_areas.reject { |served_area| served_area.local_authority_id.nil? }
    end

    def served_areas_from_advice_location_row(row)
      served_areas = []
      served_areas << ServedArea.new(office_id: row["salesforce_advice_location_id"],
                                     local_authority_id: str_or_nil(row["local_authority_ons_code"]))
      served_areas.reject { |served_area| served_area.local_authority_id.nil? }
    end

    def advice_location_row_is_excluded?(row)
      row["salesforce_advice_location_id"].nil? ||
        bool_from_val(row["excluded_from_lss_front_end"]) ||
        bool_from_val(row["excluded_from_lss_reports"])
    end

    def apply_accessibility_info!(offices, row)
      return unless offices.key? row["salesforce_advice_location_id"]

      offices[row["salesforce_advice_location_id"]][0].accessibility_information << row["advice_location_accessibility"]
    end

    def apply_volunteer_roles!(offices, row)
      return unless offices.key? row["salesforce_advice_location_id"]

      offices[row["salesforce_advice_location_id"]][0].volunteer_roles << row["volunteer_roles"]
    end

    def record_type_id_to_office_type(record_type_id)
      case record_type_id
      when "0124K000000HyUGQA0"
        :member
      when "0124K0000000qqTQAQ"
        :office
      when "0124K0000000qqUQAQ"
        :outreach
      else
        raise LssLoadError, "Unrecognised RecordTypeId #{record_type_id}"
      end
    end
  end
end
