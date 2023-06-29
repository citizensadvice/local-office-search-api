# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Bureau Details legacy API - Vacancies", swagger_doc: "v0/swagger.yaml" do
  include_context "with episerver credentials"

  path "/api/v0/vacancy/id/{id}" do
    get "Shows full details for a member" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :id, in: :path, type: :string

      response "501", "Is not yet implemented" do
        let(:id) { "id-format-to-be-defined" }

        run_test!
      end
    end
  end

  path "/api/v0/vacancy/list" do
    get "List members" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :near, in: :query, type: :string, required: false,
                description: "If near is provided then the nearest vacancies to {location} are returned."
      parameter name: :roles, in: :query, type: :string, required: false,
                description: <<~DESCRIPTION.squish
                  If roles is provided then the role types are filtered to match the list of roles (comma separated) provided.
                  e.g roles=trustee,receptionist finds all trustee or receptionist vacancies.
                DESCRIPTION

      response "501", "Is not yet implemented" do
        run_test!
      end
    end
  end
end
