# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Search Local Office API" do
  path "/api/v1/offices/" do
    get "Retrieves a single office" do
      produces "application/json"
      parameter name: :q, in: :query, type: :string, required: true, description: "the search terms to use"

      response "400", "If query is not specified" do
        schema ApiV1Schema::JSON_PROBLEM

        let(:q) { "" }

        run_test!
      end
    end
  end
end
