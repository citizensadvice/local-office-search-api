# frozen_string_literal: true

module Api
  module V0
    class LocationController < BaseController
      include Serialisers
      def get
        office = Office.find_by!(legacy_id: params[:id], office_type: :office)
        render json: location_as_v0_json(office)
      rescue ActiveRecord::RecordNotFound
        head :not_found
      end

      def list
        head :not_implemented
      end
    end
  end
end
