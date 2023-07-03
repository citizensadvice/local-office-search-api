# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Bureau Details legacy API - Vacancies", swagger_doc: "v0/swagger.yaml" do
  path "/api/v0/vacancy/id/{id}" do
    get "Shows full details for a member" do
      produces "application/json"
      parameter name: :id, in: :path, type: :string

      response "200", "fetches a single vacancy", skip: "not yet implemented" do
        schema BureauDetailsSchema::VACANCY_SCHEMA

        let(:id) { "id-format-to-be-defined" }

        run_test!
      end
    end
  end

  path "/api/v0/vacancy/list" do
    get "List members" do
      produces "application/json"
      parameter name: :near, in: :query, type: :string, required: false,
                description: "If near is provided then the nearest vacancies to the specified location are returned."
      parameter name: :roles, in: :query, type: :string, required: false,
                description: <<~DESCRIPTION.squish
                  If roles is provided then the role types are filtered to match the list of roles (comma separated) provided.
                  e.g roles=trustee,receptionist finds all trustee or receptionist vacancies.
                DESCRIPTION

      response "200", "returns the nearest vacancies to the specified location", skip: "not yet implemented" do
        schema type: :object,
               properties: {
                 type: { type: :string, enum: %w[vacancies] },
                 list: { type: :array, items: BureauDetailsSchema::VACANCY_LIST_SCHEMA }
               },
               required: %w[type list],
               additionalProperties: false

        run_test!
      end
    end
  end
end
