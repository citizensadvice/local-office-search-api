# frozen_string_literal: true

module Api
  module V0
    # rubocop:disable Metrics/ModuleLength
    module Serialisers
      private

      # rubocop:disable Metrics/AbcSize
      def member_as_v0_json(member)
        offices = Office.where(membership_number: params[:id], office_type: :office)
        offices_with_vacancies = offices.reject { |office| office.volunteer_roles.empty? }
        outreaches = Office.where(membership_number: params[:id], office_type: :outreach)

        {
          address: address_block(member, include_local_authority: true),
          membershipNumber: member.membership_number,
          name: member.name,
          serialNumber: member.legacy_id.to_s,
          charityNumber: member.charity_number,
          companyNumber: member.company_number,
          notes: member.about_text,
          services: {
            bureaux: offices.map { |office| location_as_v0_json(office) },
            outlets: outreaches.map { |office| location_as_v0_json(office) }
          },
          staff: nil,
          vacancies: offices_with_vacancies.map { |office| vacancy_as_v0_json(office) },
          website: member.website
        }
      end

      def member_as_v0_list_json(member)
        {
          address: address_block(member, include_local_authority: true),
          membershipNumber: member.membership_number,
          name: member.name,
          serialNumber: member.legacy_id.to_s
        }
      end

      def location_as_v0_json(office)
        {
          address: address_block(office, include_local_authority: true),
          membershipNumber: office.membership_number,
          name: office.name,
          serialNumber: office.legacy_id.to_s,
          inVCC: !office.phone.nil?,
          isBureau: office.office_type == "office",
          isOutlet: office.office_type == "outreach",
          features: office.accessibility_information.map { |info| accessibility_to_human_text(info) },
          notes: office.about_text,
          openingTimes: opening_time_block(office, :office),
          publicContacts: {
            email: contact_block(office.email),
            fax: [],
            minicom: [],
            telephone: contact_block(office.phone),
            website: contact_block(office.website)
          },
          telephoneTimes: opening_time_block(office, :telephone)
        }
      end
      # rubocop:enable Metrics/AbcSize

      def vacancy_as_v0_json(office)
        {
          address: address_block(office, include_local_authority: false),
          membershipNumber: office.membership_number,
          name: office.name,
          serialNumber: office.legacy_id.to_s,
          email: office.volunteer_recruitment_email || office.email,
          id: office.id,
          roles: office.volunteer_roles.map { |role| role_to_human_text(role) },
          telephone: office.phone,
          website: office.website
        }
      end

      def vacancy_as_v0_json_with_distance(office, location)
        vacancy = vacancy_as_v0_json(office)
        vacancy[:distance] = distance_in_miles(location, office.location).round(2)
        vacancy
      end

      def distance_in_miles(location1, location2)
        if location1.nil? || location2.nil?
          0
        else
          location1.distance(location2) / 1609.34
        end
      end

      def address_block(office, include_local_authority:)
        block = {
          address: office.street,
          town: office.city,
          county: office.county,
          postcode: office.postcode,
          latLong: office.location.nil? ? [0.0, 0.0] : [office.location.y, office.location.x]
        }
        if include_local_authority
          block.update({
            onsDistrictCode: office.local_authority&.id,
            localAuthority: office.local_authority&.name
          })
        end
        block
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      def opening_time_block(office, time_type)
        days = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]
        case time_type
        when :office
          opening_times = office.opening_hours
          notes = office.opening_hours_information
        when :telephone
          opening_times = office.telephone_advice_hours
          notes = office.telephone_advice_hours_information
        end
        open_days = days.reject { |day| opening_times[day.downcase.to_sym].empty? }
        open_days.map do |day|
          opening_time_range = opening_times[day.downcase.to_sym]
          {
            day:,
            start1: opening_time_range[0].beginning.strftime("%H.%M"),
            end1: opening_time_range[0].ending.strftime("%H.%M"),
            start2: opening_time_range[1]&.beginning&.strftime("%H.%M"),
            end2: opening_time_range[1]&.ending&.strftime("%H.%M"),
            notes:
          }
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

      def contact_block(value)
        return [] if value.nil?

        [{ contact: value, description: nil }]
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize
      def role_to_human_text(role)
        # derived from data science reference file: https://docs.google.com/spreadsheets/d/1_anZsdL6AX7YuysMkHsjyQkUkpLt72NsYe-oCJ25kDE/edit#gid=489969943
        case role
        when "admin_and_customer_service"
          "Admin and customer service"
        when "giving_information_advice_and_client support"
          "Giving information advice and client support"
        when "fundraising"
          "Fundraising"
        when "volunteer_recruitment_and_support"
          "Volunteer recruitment and support"
        when "trustee"
          "Trustee"
        when "researching_and_campaigning"
          "Researching and campaigning"
        when "media"
          "Media"
        when "volunteer"
          "Volunteer"
        else
          role.gsub("_", " ")
        end
      end

      def accessibility_to_human_text(accessibility_info)
        # derived from data science reference file: https://docs.google.com/spreadsheets/d/1_anZsdL6AX7YuysMkHsjyQkUkpLt72NsYe-oCJ25kDE/edit#gid=0
        case accessibility_info
        when "has_wheelchair_access"
          "Wheelchair accessible"
        when "has_staff_room"
          "Staff room"
        when "has_office"
          "Office"
        when "has_accessible_toilet"
          "Wheelchair - toilet"
        when "has_wheelchair_access_to_interview_room"
          "Wheelchair access - interview room"
        when "has_access_to_internet_advice_content"
          "Internet advice access"
        when "has_entrance_minicom"
          "Telephone (minicom)"
        when "has_onsite_parking"
          "Parking"
        when "has_clear_route_from_parking_to_entrance"
          "Route from parking/drop-off to entrance"
        when "has_internal_and_external_doors"
          "Internal and external doors"
        when "has_external_handrails"
          "External handrails"
        when "has_entrance_and_exit"
          "Building entrances and exits"
        when "has_induction_loop"
          "Induction loop"
        when "has_internal_handrails"
          "Internal handrails"
        when "has_documents_in_accessible_format"
          "Documents in accessible formats"
        when "has_accessible_signage"
          "Accessible signage"
        when "has_accessible_language"
          "Accessible language"
        when "has_adapted_lighting"
          "Adapted lighting"
        else
          accessibility_info
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/AbcSize
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
