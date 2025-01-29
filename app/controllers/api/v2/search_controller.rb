# frozen_string_literal: true

require "office_search"

module Api
  module V2
    class SearchController < ::ApplicationController
      include Serialisers

      def offices
        if search_criteria_specified?
          if search_q_is_valid?
            render json: office_search_response(params[:q])
          else
            render status: :bad_request, json: missing_search_param_json
          end
        else
          render json: all_offices(include_outreach: ActiveModel::Type::Boolean.new.cast(params[:include_outreach]))
        end
      end

      def volunteering_opportunities
        if search_criteria_specified? && search_q_is_valid?
          query_type = params[:query_type].presence || "location"
          volunteering_search_by_query_type(query_type)
        else
          render status: :bad_request, json: missing_search_type_json
        end
      end

      private

      def search_criteria_specified?
        params.key?(:q)
      end

      def search_q_is_valid?
        !(params[:q] || "").empty?
      end

      def all_offices(include_outreach: false)
        office_types = [:office]
        office_types << :outreach if include_outreach

        { match_type: "all", results: Office.where(office_type: office_types).map { |office| office_as_search_result_json(office) } }
      end

      def office_search_response(query)
        offices, normalised_location = OfficeSearch.by_location query, only_in_same_local_authority: true
      rescue OfficeSearch::UnknownLocationError
        { match_type: "unknown", results: [] }
      rescue OfficeSearch::OutOfAreaError => e
        { match_type: "out_of_area_#{e.country}", results: [] }
      else
        { match_type: normalised_location.nil? ? "fuzzy" : "exact", results: offices.map { |office| office_as_search_result_json(office) } }
      end

      def volunteering_search_by_query_type(query_type)
        case query_type
        when "location"
          render json: volunteering_location_search_response(params[:q])
        when "member"
          render json: volunteering_member_search_response(params[:q])
        else
          render status: :bad_request, json: missing_search_param_json
        end
      end

      def volunteering_location_search_response(query)
        offices, normalised_location = OfficeSearch.by_location query, only_with_vacancies: true
      rescue OfficeSearch::UnknownLocationError
        { match_type: "unknown", results: [] }
      rescue OfficeSearch::OutOfAreaError => e
        { match_type: "out_of_area_#{e.country}", results: [] }
      else
        { match_type: normalised_location.nil? ? "fuzzy" : "exact", results: offices.map do |office|
          volunteering_opportunity_as_search_result_json(office, normalised_location)
        end }
      end

      def volunteering_member_search_response(member_id)
        member = Office.find_by(id: member_id, office_type: "member")
        return { match_type: "unknown", results: [] } if member.nil?

        offices_with_vacancies = member.children.where.not(volunteer_roles: [])
        { match_type: "member", results: offices_with_vacancies.map { |office| volunteering_opportunity_as_search_result_json(office) } }
      end

      def missing_search_param_json
        { type: "https://local-office-search.citizensadvice.org.uk/schemas/v2/errors#missing-param", status: 400, title: "Required parameter (q) missing" }
      end

      def missing_search_type_json
        { type: "https://local-office-search.citizensadvice.org.uk/schemas/v2/errors#missing-param", status: 400, title: "Required parameter (query_type) set to invalid value" }
      end
    end
  end
end
