# frozen_string_literal: true

module Api
  module V0
    class MemberController < BaseController
      include Serialisers

      def get
        office = Office.find_by!(membership_number: params[:id], office_type: :member)
        render json: member_as_v0_json(office)
      rescue ActiveRecord::RecordNotFound
        head :not_found
      end

      def list
        render json: { type: "member", list: Office.where(office_type: :member).map { |office| member_as_v0_list_json(office) } }
      end
    end
  end
end
