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
                 postcode: str_or_nil(row["postcode"]),
                 location: point_wkt_or_nil(row["latitude"], row["longitude"]),
                 local_authority_id: row["local_authority_ons_code"],
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
                 postcode: str_or_nil(row["postcode"]),
                 location: point_wkt_or_nil(row["latitude"], row["longitude"]),
                 email: str_or_nil(row["enquiries_email"]),
                 website: str_or_nil(row["public_website"]),
                 phone: str_or_nil(row["phone"]),
                 opening_hours_information: str_or_nil(row["face_to_face_advice_hours_information"]),
                 telephone_advice_hours_information: str_or_nil(row["telephone_advice_hours_information"])
    end
    # rubocop:enable Metrics/AbcSize

    def apply_opening_hours!(offices, row)
      return unless row["session_type"] != "null" && offices.key?(row["advice_location_salesforce_id"])

      offices[row["advice_location_salesforce_id"]].write_attribute column_from_row(row), shift_from_row(row)
    end

    def apply_accessibility_info!(offices, row)
      offices[row["salesforce_advice_location_id"]].accessibility_information << row["advice_location_accessibility"]
    end

    def apply_volunteer_roles!(offices, row)
      offices[row["salesforce_advice_location_id"]].volunteer_roles << row["advice_location_volunteer_roles_recruiting_status"]
    end

    def column_from_row(row)
      case row["session_type"]
      when "Local office opening hours"
        "opening_hours_#{row['session_day'].downcase}".to_sym
      when "Telephone advice hours"
        "telephone_advice_hours_#{row['session_day'].downcase}".to_sym
      else
        raise LssLoadError, "Unrecognised opening hour type #{row['session_type']}"
      end
    end

    def shift_from_row(row)
      start_time = str_or_nil(row["session_start_time"])
      end_time = str_or_nil(row["session_end_time"])
      return nil if start_time.nil? || end_time.nil?

      beginning = tod_from_val(start_time)
      ending = tod_from_val(end_time)
      Tod::Shift.new(beginning, ending) unless beginning > ending
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
