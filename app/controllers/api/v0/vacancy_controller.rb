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
        head :not_implemented
      end
    end
  end
end
