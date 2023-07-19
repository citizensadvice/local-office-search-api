# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Search Local Office API" do
  path "/api/v1/offices/" do
    get "Retrieves a single office" do
      produces "application/json"
      parameter name: :q, in: :query, type: :string, required: true, description: "the search terms to use"

      response "200", "a list of search results" do
        schema "$schema": "https://json-schema.org/draft/2019-09/schema",
               "$id": "https://local-office-search.citizensadvice.org.uk/schemas/v1/results",
               type: :object,
               properties: {
                 match_type: { type: :string, enum: %w[exact fuzzy unknown out_of_area_scotland out_of_area_ni],
                               description: %(
                                * `exact` means the search term matched an exact location, so only offices which serve the exact location
                                   are shown (this could include no locations).
                                * `fuzzy` means the search term matched a wider locality and not an individual point, so the results may
                                   include offices which can not serve that exact location.
                                * `unknown` means the search term was unable to be interpreted or matched to a location
                                  (so there are no results).
                                * `out_of_area_scotland` and `out_of_area_ni` means the search term matched exactly, but to a location in
                                  Scotland or Northern Ireland which is not in the network coverage area.
                                ) },
                 results: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string }
                     },
                     required: %i[id],
                     additionalProperties: false
                   }
                 }
               },
               required: %i[match_type results],
               additionalProperties: false

        context "when the location is known, but there is no LCA in that area" do
          let(:local_authority_id) { LocalAuthority.create!(id: "X0001234", name: "Testshire").id }

          let(:postcode) { Postcode.create! canonical: "XX4 6LA", local_authority_id:, location: "POINT(-0.78 52.66)" }

          let(:q) { postcode.canonical }

          run_test! do |response|
            expect(JSON.parse(response.body).deep_symbolize_keys).to eq({ match_type: "exact", results: [] })
          end
        end

        context "when the location is known, and there is an LCA in that area" do
          let(:local_authority_id) { LocalAuthority.create!(id: "X0001234", name: "Testshire").id }

          let(:postcode) { Postcode.create! canonical: "XX4 6LA", local_authority_id:, location: "POINT(-0.78 52.66)" }

          let(:q) { postcode.canonical }

          let(:office) do
            Office.new id: generate_salesforce_id,
                       office_type: :office,
                       name: "Testshire Citizens Advice",
                       local_authority_id:
          end

          before { office.save! }

          run_test! do |response|
            expect(JSON.parse(response.body).deep_symbolize_keys).to eq({ match_type: "exact", results: [{ id: office.id }] })
          end
        end

        context "when the location is known, and there is an LCA in that area plus LCAs out of area" do
          let(:local_authority_id) { LocalAuthority.create!(id: "X0001234", name: "Testshire").id }

          let(:postcode) { Postcode.create! canonical: "XX4 6LA", local_authority_id:, location: "POINT(-0.78 52.66)" }

          let(:q) { postcode.canonical }

          let(:office) do
            Office.new id: generate_salesforce_id,
                       office_type: :office,
                       name: "Testshire Citizens Advice",
                       local_authority_id:
          end

          before do
            office.save!
            other_la = LocalAuthority.create!(id: "X00012345", name: "Testtown")
            Office.create! id: generate_salesforce_id,
                           office_type: :office,
                           name: "Testtown Citizens Advice",
                           local_authority_id: other_la.id
          end

          run_test! do |response|
            expect(JSON.parse(response.body).deep_symbolize_keys).to eq({ match_type: "exact", results: [{ id: office.id }] })
          end
        end

        context "when the postcode is Scottish" do
          let(:local_authority_id) { LocalAuthority.create!(id: "S12000036", name: "Edinburgh").id }

          let(:postcode) { Postcode.create! canonical: "EH1 1AA", local_authority_id:, location: "POINT(-3.188106 55.95365)" }

          let(:q) { postcode.canonical }

          run_test! do |response|
            expect(JSON.parse(response.body).deep_symbolize_keys).to eq({ match_type: "out_of_area_scotland", results: [] })
          end
        end

        context "when the postcode is Northern Irish" do
          let(:local_authority_id) { LocalAuthority.create!(id: "N09000003", name: "Belfast").id }

          let(:postcode) { Postcode.create! canonical: "BT1 1AA", local_authority_id:, location: "POINT(-5.922291 54.602444)" }

          let(:q) { postcode.canonical }

          run_test! do |response|
            expect(JSON.parse(response.body).deep_symbolize_keys).to eq({ match_type: "out_of_area_ni", results: [] })
          end
        end

        context "when the location is unknown" do
          let(:q) { "AB1 2CD" }

          run_test! do |response|
            expect(JSON.parse(response.body).deep_symbolize_keys).to eq({ match_type: "unknown", results: [] })
          end
        end
      end

      response "400", "If query is not specified" do
        schema ApiV1Schema::JSON_PROBLEM

        let(:q) { "" }

        run_test!
      end
    end
  end
end
