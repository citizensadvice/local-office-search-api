# frozen_string_literal: true

require "office_search"

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
        offices, normalised_location = OfficeSearch.by_location(params[:near], only_with_vacancies: true)
        render json: { type: "vacancies", list: offices.map { |office| vacancy_as_v0_json_with_distance(office, normalised_location) } }
      rescue OfficeSearch::UnknownLocationError
        render json: { type: "no results" }
      rescue OfficeSearch::OutOfAreaError => e
        render json: { type: "Out of bounds #{e.country_name}" }
      end
    end
  end
end
