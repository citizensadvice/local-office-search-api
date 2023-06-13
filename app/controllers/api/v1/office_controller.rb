# frozen_string_literal: true

module Api
  module V1
    class OfficeController < ::ApplicationController
      def show
        office = Office.find(params[:id])
        render json: office_as_json(office)
      end

      private

      # rubocop:disable Metrics/AbcSize
      def office_as_json(office)
        {
          id: office.id,
          member_id: office.parent_id,
          name: office.name,
          about_text: office.about_text,
          accessibility_information: office.accessibility_information,
          street: office.street,
          city: office.city,
          postcode: office.postcode,
          location: office.location.as_json,
          email: office.email,
          website: office.website,
          phone: office.phone,
          opening_hours: {
            information: office.opening_hours_information,
            monday: opening_hours_as_json(office.opening_hours_monday),
            tuesday: opening_hours_as_json(office.opening_hours_tuesday),
            wednesday: opening_hours_as_json(office.opening_hours_wednesday),
            thursday: opening_hours_as_json(office.opening_hours_thursday),
            friday: opening_hours_as_json(office.opening_hours_friday),
            saturday: opening_hours_as_json(office.opening_hours_saturday),
            sunday: opening_hours_as_json(office.opening_hours_sunday)
          },
          telephone_advice_hours: {
            information: office.telephone_advice_hours_information,
            monday: opening_hours_as_json(office.telephone_advice_hours_monday),
            tuesday: opening_hours_as_json(office.telephone_advice_hours_tuesday),
            wednesday: opening_hours_as_json(office.telephone_advice_hours_wednesday),
            thursday: opening_hours_as_json(office.telephone_advice_hours_thursday),
            friday: opening_hours_as_json(office.telephone_advice_hours_friday),
            saturday: opening_hours_as_json(office.telephone_advice_hours_saturday),
            sunday: opening_hours_as_json(office.telephone_advice_hours_sunday)
          }
        }
      end
      # rubocop:enable Metrics/AbcSize

      def opening_hours_as_json(opening_hours)
        return nil if opening_hours.nil?

        { opens: opening_hours.beginning.strftime("%H:%M:%S"), closes: opening_hours.ending.strftime("%H:%M:%S") }
      end
    end
  end
end
