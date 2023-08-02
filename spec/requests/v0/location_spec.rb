# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Bureau Details legacy API - Locations", swagger_doc: "v0/swagger.yaml" do
  include_context "with episerver credentials"

  path "/api/v0/json/location/id/{serial_number}" do
    get "Show full details for a location" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :serial_number, in: :path, type: :string, description: "{serial_number} is the locations serial number."

      response "501", "is a deprecated API which has not been reimplemented" do
        let(:serial_number) { "10002" }

        run_test!
      end
    end
  end

  path "/api/v0/json/location/list" do
    get "List members" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :near, in: :query, type: :string, required: false,
                description: <<~DESCRIPTION.squish
                  If near is provided then the nearest locations to the value are returned. Locations are ordered so those
                  in the same local authority of are promoted.
                DESCRIPTION
      parameter name: :bureau, in: :query, type: :boolean, required: false, default: true,
                description: "If bureau is set to false then locations of type bureau will not be returned."
      parameter name: :outlet, in: :query, type: :boolean, required: false, default: false,
                description: "If outlet is set to true then outreaches will also be returned."

      response "501", "is a deprecated API which has not been reimplemented" do
        run_test!
      end
    end
  end
end
