# frozen_string_literal: true

require "office_search"

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

      def search
        if search_q_is_valid?
          render json: search_response(params[:q])
        else
          render status: :bad_request, json: missing_search_param_json
        end
      end

      private

      def legacy_id?
        params[:id].match(/^\d+$/)
      end

      def search_q_is_valid?
        !(params[:q] || "").empty?
      end

      def search_response(query)
        offices, = OfficeSearch.search_by_location query, only_in_same_local_authority: true
      rescue OfficeSearch::SearchUnknownLocationError
        { match_type: "unknown", results: [] }
      rescue OfficeSearch::SearchOutOfAreaError => e
        { match_type: "out_of_area_#{e.country}", results: [] }
      else
        { match_type: "exact", results: offices.map { |office| { id: office.id } } }
      end

      def fetch_and_render_office
        office = Office.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render status: :not_found, json: not_found_json
      else
        render json: office
      end

      def redirect_from_legacy_id_to_new
        office = Office.find_by(legacy_id: params[:id].to_i)
        if office.nil?
          render status: :not_found, json: not_found_json
        else
          redirect_to api_v1_office_url(office)
        end
      end

      def not_found_json
        { type: "https://local-office-search.citizensadvice.org.uk/schemas/v1/errors#not-found", status: 404, title: "Office not found" }
      end

      def missing_search_param_json
        { type: "https://local-office-search.citizensadvice.org.uk/schemas/v1/errors#missing-param", status: 400, title: "Required parameter (q) missing" }
      end
    end
  end
end
