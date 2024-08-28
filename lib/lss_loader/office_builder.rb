# frozen_string_literal: true

module LssLoader
  class OfficeBuilder
    include CsvHelpers

    def initialize(members_csv, advice_locations_csv, accessibility_info_csv, volunteer_roles_csv)
      @members_csv = members_csv
      @advice_locations_csv = advice_locations_csv
      @accessibility_info_csv = accessibility_info_csv
      @volunteer_roles_csv = volunteer_roles_csv
    end

    def build
      @offices = {}
      @served_areas = []
      @valid_local_authority_ids = LocalAuthority.ids.to_set

      load_members_csv!
      load_advice_locations_csv!
      load_accessibility_info_csv!
      load_volunteer_roles_csv!
      nullify_dangling_parent_ids!
      nullify_dangling_local_authority_ids!

      [@offices.values, @served_areas]
    end

    private

    def load_members_csv!
      @members_csv.each do |row|
        build_office_from_member_row(row)
        build_served_areas_from_member_row(row)
      end
    end

    def load_advice_locations_csv!
      @advice_locations_csv.each do |row|
        next if advice_location_row_is_excluded?(row)

        build_office_from_advice_location_row(row)
        build_served_areas_from_advice_location_row(row)
      end
    end

    def load_accessibility_info_csv!
      @accessibility_info_csv.each do |row|
        apply_accessibility_info_from_row(row)
      end
    end

    def load_volunteer_roles_csv!
      @volunteer_roles_csv.each do |row|
        apply_volunteer_roles_from_row(row)
      end
    end

    # rubocop:disable Metrics/AbcSize
    def build_office_from_member_row(row)
      @offices[row["salesforce_id"]] = Office.new(
        id: row["salesforce_id"],
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
      )
    end

    def build_office_from_advice_location_row(row)
      @offices[row["salesforce_advice_location_id"]] = Office.new(
        id: row["salesforce_advice_location_id"],
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
      )
    end
    # rubocop:enable Metrics/AbcSize

    def build_served_areas_from_member_row(row)
      ["local_authority_ons_code"].each do |served_area_column|
        local_authority_id = str_or_nil(row[served_area_column])
        if @valid_local_authority_ids.include?(local_authority_id)
          @served_areas << ServedArea.new(office_id: row["salesforce_id"], local_authority_id:)
        end
      end
    end

    def build_served_areas_from_advice_location_row(row)
      ["local_authority_ons_code"].each do |served_area_column|
        local_authority_id = str_or_nil(row[served_area_column])
        if @valid_local_authority_ids.include?(local_authority_id)
          @served_areas << ServedArea.new(office_id: row["salesforce_advice_location_id"], local_authority_id:)
        end
      end
    end

    def apply_accessibility_info_from_row(row)
      return unless @offices.key? row["salesforce_advice_location_id"]

      @offices[row["salesforce_advice_location_id"]].accessibility_information << row["advice_location_accessibility"]
    end

    def apply_volunteer_roles_from_row(row)
      return unless @offices.key? row["salesforce_advice_location_id"]

      @offices[row["salesforce_advice_location_id"]].volunteer_roles << row["volunteer_roles"]
    end

    def nullify_dangling_parent_ids!
      orphaned_offices = @offices.values.reject { |office| office.parent_id.nil? || @offices.key?(office.parent_id) }
      orphaned_offices.each { |office| office.parent_id = nil }
    end

    def nullify_dangling_local_authority_ids!
      orphaned_offices = @offices.values.reject { |office| @valid_local_authority_ids.include? office.local_authority_id }
      orphaned_offices.each { |office| office.local_authority_id = nil }
    end

    def advice_location_row_is_excluded?(row)
      row["salesforce_advice_location_id"].nil? ||
        bool_from_val(row["excluded_from_lss_front_end"]) || bool_from_val(row["excluded_from_lss_reports"])
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
