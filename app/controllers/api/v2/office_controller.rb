# frozen_string_literal: true

require "office_search"

module Api
  module V2
    class OfficeController < ::ApplicationController
      include Serialisers

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
        office = Office.find_by("lower(id) = ?", params[:id].downcase)
        if office.nil?
          render status: :not_found, json: not_found_json
        elsif params[:id] == office.id
          render json: office_as_json(office)
        else
          redirect_to api_v2_office_url(office)
        end
      end

      def redirect_from_legacy_id_to_new
        office = Office.find_by(legacy_id: params[:id].to_i)
        if office.nil?
          render status: :not_found, json: not_found_json
        else
          redirect_to api_v2_office_url(office)
        end
      end

      def not_found_json
        { type: "https://local-office-search.citizensadvice.org.uk/schemas/v2/errors#not-found", status: 404, title: "Office not found" }
      end
    end
  end
end
