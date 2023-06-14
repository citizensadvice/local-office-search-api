# frozen_string_literal: true

module Api
  module V1
    class OfficeController < ::ApplicationController
      def show
        if legacy_id?
          redirect_from_legacy_id_to_new
        else
          fetch_and_render_office
        end
      end

      private

      def legacy_id?
        params[:id].match(/^\d+$/)
      end

      def fetch_and_render_office
        office = Office.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render status: :not_found, json: not_found_json
      else
        render json: office_as_json(office)
      end

      def redirect_from_legacy_id_to_new
        office = Office.find_by(legacy_id: params[:id].to_i)
        if office.nil?
          render status: :not_found, json: not_found_json
        else
          redirect_to api_v1_office_url(office)
        end
      end

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

      def not_found_json
        { type: "https://local-office-search.citizensadvice.org.uk/schemas/v1/errors#not-found", status: 404, title: "Office not found" }
      end
    end
  end
end
