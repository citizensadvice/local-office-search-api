# frozen_string_literal: true

module Api
  module V0
    class MemberController < ::ApplicationController
      def get
        office = Office.find_by!(membership_number: params[:id], office_type: :member)
        render json: member_as_v0_json(office)
      rescue ActiveRecord::RecordNotFound
        head :not_found
      end

      def list
        head :not_implemented
      end

      private

      # rubocop:disable Metrics/AbcSize
      def member_as_v0_json(member)
        {
          address: address_block(member),
          membershipNumber: member.membership_number,
          name: member.name,
          serialNumber: member.legacy_id.to_s,
          charityNumber: member.charity_number,
          companyNumber: member.company_number,
          notes: member.about_text,
          services: {
            bureaux: Office.where(membership_number: params[:id], office_type: :office).map { |office| location_as_v0_json(office) },
            outlets: Office.where(membership_number: params[:id], office_type: :outreach).map { |office| location_as_v0_json(office) }
          },
          staff: nil,
          vacancies: [],
          website: member.website
        }
      end

      def location_as_v0_json(office)
        {
          address: address_block(office),
          membershipNumber: office.membership_number,
          name: office.name,
          serialNumber: office.legacy_id.to_s,
          inVCC: !office.phone.nil?,
          isBureau: office.office_type == "office",
          isOutlet: office.office_type == "outreach",
          features: office.accessibility_information,
          notes: office.about_text,
          openingTimes: opening_time_block(office, "opening"),
          publicContacts: {
            email: contact_block(office.email),
            fax: [],
            minicom: [],
            telephone: contact_block(office.phone),
            website: contact_block(office.website)
          },
          telephoneTimes: opening_time_block(office, "telephone_advice")
        }
      end
      # rubocop:enable Metrics/AbcSize

      def address_block(office)
        {
          address: office.street,
          town: office.city,
          county: nil,
          postcode: office.postcode,
          onsDistrictCode: office.local_authority&.id,
          localAuthority: office.local_authority&.name,
          latLong: [office.location.y, office.location.x]
        }
      end

      def opening_time_block(office, time_type)
        days = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]
        open_days = days.reject { |day| office["#{time_type}_hours_#{day.downcase}"].nil? }
        open_days.map do |day|
          opening_time_range = office["#{time_type}_hours_#{day.downcase}"]
          if opening_time_range.nil?
            nil
          else
            {
              day:,
              start1: opening_time_range.beginning.strftime("%H.%M"),
              end1: opening_time_range.ending.strftime("%H.%M"),
              start2: nil,
              end2: nil,
              notes: office["#{time_type}_hours_information"]
            }
          end
        end
      end

      def contact_block(value)
        return [] if value.nil?

        [{ contact: value, description: nil }]
      end
    end
  end
end
