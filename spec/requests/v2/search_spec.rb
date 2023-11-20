# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Search Local Office API" do
  path "/api/v2/offices/" do
    get "Searches for offices" do
      produces "application/json"
      parameter name: :q, in: :query, type: :string, required: true, description: "the search terms to use"

      response "200", "a list of search results" do
        schema ApiV2Schema::SEARCH_RESULTS

        context "when the location is known, but there is no LCA in that area" do
          let(:local_authority_id) { LocalAuthority.create!(id: "X0001234", name: "Testshire").id }

          let(:postcode) { Postcode.create! canonical: "XX4 6LA", local_authority_id:, location: "POINT(-0.78 52.66)" }

          let(:q) { postcode.canonical }

          run_test! do |response|
            expect_result_ids_in_response response, "exact", []
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
            expect_result_ids_in_response response, "exact", [office.id]
          end

          context "with the LCA allowing drop-ins" do
            let(:office) do
              Office.new id: generate_salesforce_id,
                         office_type: :office,
                         name: "Testshire Citizens Advice",
                         local_authority_id:,
                         allows_drop_ins: true
            end

            run_test! do |response|
              expect_contact_methods_to_match response, ["drop_in"]
            end
          end

          context "with the LCA contactable by phone" do
            let(:office) do
              Office.new id: generate_salesforce_id,
                         office_type: :office,
                         name: "Testshire Citizens Advice",
                         local_authority_id:,
                         phone: "01234 567890"
            end

            run_test! do |response|
              expect_contact_methods_to_match response, ["phone"]
            end
          end

          context "with the LCA having an email address" do
            let(:office) do
              Office.new id: generate_salesforce_id,
                         office_type: :office,
                         name: "Testshire Citizens Advice",
                         local_authority_id:,
                         email: "cab@example.com"
            end

            run_test! do |response|
              expect_contact_methods_to_match response, ["email"]
            end
          end
        end

        context "when the location is Scottish" do
          let(:local_authority_id) { LocalAuthority.create!(id: "S12000036", name: "Edinburgh").id }

          let(:postcode) { Postcode.create! canonical: "EH1 1AA", local_authority_id:, location: "POINT(-3.188106 55.95365)" }

          let(:q) { postcode.canonical }

          run_test! do |response|
            expect_result_ids_in_response response, "out_of_area_scotland", []
          end
        end

        context "when the location is Northern Irish" do
          let(:local_authority_id) { LocalAuthority.create!(id: "N09000003", name: "Belfast").id }

          let(:postcode) { Postcode.create! canonical: "BT1 1AA", local_authority_id:, location: "POINT(-5.922291 54.602444)" }

          let(:q) { postcode.canonical }

          run_test! do |response|
            expect_result_ids_in_response response, "out_of_area_ni", []
          end
        end

        context "when the location is fuzzily matched" do
          let(:local_authority_id) { LocalAuthority.create!(id: "X0001234", name: "Testshire").id }
          let(:q) { "Testshire" }

          let(:office) do
            Office.new id: generate_salesforce_id,
                       office_type: :office,
                       name: "Testshire Citizens Advice",
                       local_authority_id:
          end

          before { office.save! }

          run_test! do |response|
            expect_result_ids_in_response response, "fuzzy", [office.id]
          end
        end

        context "when the location is unknown" do
          let(:q) { "AB1 2CD" }

          run_test! do |response|
            expect_result_ids_in_response response, "unknown", []
          end
        end
      end

      response "400", "If query is not specified" do
        schema ApiV2Schema::JSON_PROBLEM

        let(:q) { "" }

        run_test!
      end
    end
  end

  def expect_result_ids_in_response(response, match_type, ids)
    body = JSON.parse(response.body).deep_symbolize_keys

    expect(body[:match_type]).to eq match_type
    expect(body[:results].pluck(:id)).to eq ids
  end

  def expect_contact_methods_to_match(response, expected)
    body = JSON.parse(response.body).deep_symbolize_keys

    expect(body[:results][0][:contact_methods]).to eq(expected)
  end
end
