# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Search Local Office API", swagger_doc: "v2/swagger.yaml" do
  path "/api/v2/offices/" do
    get "Searches for offices" do
      produces "application/json"
      parameter name: :q, in: :query, type: :string, required: false,
                description: "the search terms to use (when not specified returns all)"
      parameter name: :include_outreach, in: :query, type: :boolean, required: false, default: false,
                description: "include outreaches when listing offices"

      response "200", "all offices when no query string is set" do
        schema ApiV2Schema::OFFICE_SEARCH_RESULTS

        let(:local_authority_id) { LocalAuthority.create!(id: "X0001234", name: "Testshire").id }

        let(:office) do
          Office.new id: generate_salesforce_id,
                     office_type: :office,
                     name: "Testshire Citizens Advice"
        end

        let(:outreach) do
          Office.new id: generate_salesforce_id,
                     office_type: :outreach,
                     name: "Testshire Citizens Advice outreach"
        end

        before do
          office.save!
          outreach.save!
          ServedArea.create!(local_authority_id:, office:)
        end

        context "when include_outreach is not specified (default false)" do
          run_test! do |response|
            expect_result_ids_in_response response, "all", [office.id]
          end
        end

        context "when include_outreach is true" do
          let(:include_outreach) { true }

          run_test! do |response|
            expect_result_ids_in_response response, "all", [office.id, outreach.id]
          end
        end
      end

      response "200", "a list of search results when a query string is specified" do
        schema ApiV2Schema::OFFICE_SEARCH_RESULTS

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
                       name: "Testshire Citizens Advice"
          end

          before do
            office.save!
            ServedArea.create!(local_authority_id:, office:)
          end

          run_test! do |response|
            expect_result_ids_in_response response, "exact", [office.id]
          end

          context "with the LCA allowing drop-ins" do
            let(:office) do
              Office.new id: generate_salesforce_id,
                         office_type: :office,
                         name: "Testshire Citizens Advice",
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
                       name: "Testshire Citizens Advice"
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

  path "/api/v2/volunteering-opportunities/" do
    get "Searches for volunteering opportunities" do
      produces "application/json"
      parameter name: :q, in: :query, type: :string, required: true,
                description: "the search terms to use"
      parameter name: :query_type, in: :query, required: true,
                enum: {
                  location: "treat q as a location to search around",
                  member: "treat q as a member ID to return all the opportunities for"
                },
                default: "location",
                description: "the search terms to use"

      response "200", "a list of search results when a query string is specified" do
        schema ApiV2Schema::VOLUNTEERING_SEARCH_RESULTS

        context "when a fuzzy search is done" do
          let(:q) { "Testshire" }
          let(:query_type) { "location" }

          let(:office) do
            Office.new id: generate_salesforce_id,
                       office_type: :office,
                       name: "Testshire Citizens Advice",
                       volunteer_roles: ["admin_and_customer_service"]
          end

          before do
            office.save!
          end

          run_test! do |response|
            expect_result_ids_in_response response, "fuzzy", [office.id]
          end
        end

        context "when there are offices with no volunteering opportunities" do
          let(:q) { "Testshire" }
          let(:query_type) { "location" }

          let(:office) do
            Office.new id: generate_salesforce_id,
                       office_type: :office,
                       name: "Testshire Citizens Advice",
                       volunteer_roles: ["admin_and_customer_service"]
          end

          before do
            Office.new(id: generate_salesforce_id, office_type: :office, name: "Testshire Testtown")
            office.save!
          end

          run_test! do |response|
            expect_result_ids_in_response response, "fuzzy", [office.id]
          end
        end

        context "when an exact search is done" do
          let(:q) { "AA1 1AA" }
          let(:query_type) { "location" }

          let(:nearest_office) do
            Office.new(id: generate_salesforce_id,
                       office_type: :office,
                       name: "Testshire Citizens Advice",
                       volunteer_roles: ["admin_and_customer_service"],
                       location: "POINT(2.0 2.0)")
          end

          let(:far_office) do
            Office.new(id: generate_salesforce_id,
                       office_type: :office,
                       name: "Othertown Citizens Advice",
                       volunteer_roles: ["admin_and_customer_service"],
                       location: "POINT(3.0 3.0)")
          end

          before do
            Postcode.create!(canonical: "AA1 1AA",
                             local_authority_id: LocalAuthority.create!(id: "X00000001", name: "Testshire").id,
                             location: "POINT(1.0 1.0)")
            nearest_office.save!
            far_office.save!
          end

          run_test! do |response|
            expect_result_ids_in_response response, "exact", [nearest_office.id, far_office.id]
          end
        end

        context "when a search by member is done and results match" do
          let(:q) { member.id }
          let(:query_type) { "member" }

          let(:member) do
            Office.new(id: generate_salesforce_id,
                       office_type: :member,
                       name: "Testshire Citizens Advice")
          end

          let(:member_office) do
            Office.new(id: generate_salesforce_id,
                       parent_id: member.id,
                       office_type: :office,
                       name: "Testshire Citizens Advice",
                       volunteer_roles: ["admin_and_customer_service"],
                       location: "POINT(2.0 2.0)")
          end

          before do
            member.save!
            member_office.save!
            other_member = Office.create(id: generate_salesforce_id,
                                         office_type: :member,
                                         name: "Othertown Citizens Advice")
            Office.create(id: generate_salesforce_id,
                          parent_id: other_member.id,
                          office_type: :office,
                          name: "Othertown Citizens Advice",
                          volunteer_roles: ["admin_and_customer_service"],
                          location: "POINT(3.0 3.0)")
          end

          run_test! do |response|
            expect_result_ids_in_response response, "member", [member_office.id]
          end
        end

        context "when a search by member is done and there is no member with that ID" do
          let(:q) { generate_salesforce_id }
          let(:query_type) { "member" }

          run_test! do |response|
            expect_result_ids_in_response response, "unknown", []
          end
        end
      end

      response "400", "If query is not specified" do
        schema ApiV2Schema::JSON_PROBLEM

        let(:q) { "" }
        let(:query_type) { "location" }

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
