# frozen_string_literal: true

module Api
  module V2
    class VolunteeringOpportunityController < ::ApplicationController
      include Serialisers

      def show
        office = Office.find_by(id: params[:id])

        if office.nil?
          render status: :not_found, json: not_found_json
        elsif office.volunteer_roles.empty?
          render status: :not_found, json: no_volunteering_opportunities_json
        else
          render json: volunteering_opportunity_as_json(office)
        end
      end

      private

      def not_found_json
        { type: "https://local-office-search.citizensadvice.org.uk/schemas/v2/errors#not-found", status: 404, title: "Office not found" }
      end

      def no_volunteering_opportunities_json
        { type: "https://local-office-search.citizensadvice.org.uk/schemas/v2/errors#not-found", status: 404, title: "Office has no volunteering opportunities" }
      end
    end
  end
end
