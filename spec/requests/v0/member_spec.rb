# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Bureau Details legacy API - Members", swagger_doc: "v0/swagger.yaml" do
  include_context "with episerver credentials"

  path "/api/v0/member/id/{id}" do
    get "Shows full details for a member" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :id, in: :path, type: :string,
                description: <<-DESCRIPTION.squish
                  {id} can be a serial number, eg 100002, or a membership number, eg 70/0023
                DESCRIPTION

      response "501", "Is not yet implemented" do
        let(:id) { "70/0023" }

        run_test!
      end
    end
  end

  path "/api/v0/member/list" do
    get "List members" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :near, in: :query, type: :string, required: false,
                description: <<~DESCRIPTION.squish
                  Without near all members will be show in alphabetical order. If near is provided then the nearest
                  members to the parameter will be returned.
                DESCRIPTION

      response "501", "is a deprecated API which has not been reimplemented" do
        run_test!
      end
    end
  end
end
