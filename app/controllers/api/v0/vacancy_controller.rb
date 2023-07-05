# frozen_string_literal: true

module Api
  module V0
    class VacancyController < BaseController
      include Serialisers

      def get
        office = Office.find(params[:id])
        head :not_found if office.volunteer_roles.empty?
        render json: vacancy_as_v0_json(office) unless office.volunteer_roles.empty?
      rescue ActiveRecord::RecordNotFound
        head :not_found
      end

      def list
        offices, normalised_location = Office.search_by_location(params[:near], only_with_vacancies: true)
        render json: { type: "vacancies", list: offices.map { |office| vacancy_as_v0_json_with_distance(office, normalised_location) } }
      rescue Office::SearchNoResultsError
        render json: { type: "no results" }
      rescue Office::SearchOutOfAreaError => e
        render json: { type: "Out of bounds #{e.country}" }
      rescue Office::SearchAmbiguousError => e
        render json: { type: "locality", list: e.options }
      end
    end
  end
end
