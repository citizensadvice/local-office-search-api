# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Bureau Details legacy API - Vacancies", swagger_doc: "v0/swagger.yaml" do
  include_context "with episerver credentials"

  path "/api/v0/vacancy/id/{id}" do
    get "Shows full details for a member" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :id, in: :path, type: :string

      response "200", "fetches a single vacancy" do
        schema BureauDetailsSchema::VACANCY_SCHEMA

        let(:id) do
          local_authority = LocalAuthority.create! id: "E05XXTEST", name: "Borsetshire"

          office = Office.create!(id: generate_salesforce_id,
                                  name: "Citizens Advice Felpersham North",
                                  street: "14 Shakespeare Road",
                                  city: "Felpersham",
                                  postcode: "FX1 7QW",
                                  location: "POINT(-0.7646468 52.0451619)",
                                  legacy_id: 2,
                                  membership_number: "55/5555",
                                  office_type: :office,
                                  email: "felphersham@example.com",
                                  website: "http://www.felpershamcab.org.uk",
                                  phone: "01632 555 555",
                                  volunteer_roles: ["Receptionist", "Volunteer recruitment and support"],
                                  local_authority:)
          office.id
        end

        # rubocop:disable RSpec/ExampleLength
        run_test! do |response|
          expect(JSON.parse(response.body, symbolize_names: true)).to eq({
            address: {
              address: "14 Shakespeare Road",
              town: "Felpersham",
              county: nil,
              postcode: "FX1 7QW",
              latLong: [52.0451619, -0.7646468]
            },
            membershipNumber: "55/5555",
            name: "Citizens Advice Felpersham North",
            serialNumber: "2",
            email: "felphersham@example.com",
            id:,
            roles: [
              "Receptionist",
              "Volunteer recruitment and support"
            ],
            telephone: "01632 555 555",
            website: "http://www.felpershamcab.org.uk"
          })
        end
        # rubocop:enable RSpec/ExampleLength
      end

      response "404", "when ID is not valid" do
        let(:id) { "not-a-vacancy-id" }

        run_test!
      end

      response "404", "when ID references something with no roles" do
        let(:id) do
          office = Office.create!(id: generate_salesforce_id,
                                  name: "Citizens Advice Felpersham North",
                                  office_type: :office,
                                  volunteer_roles: [])
          office.id
        end

        run_test!
      end
    end
  end

  path "/api/v0/vacancy/list" do
    get "List members" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :near, in: :query, type: :string, required: false,
                description: "If near is provided then the nearest vacancies to the specified location are returned."
      parameter name: :roles, in: :query, type: :string, required: false,
                description: <<~DESCRIPTION.squish
                  If roles is provided then the role types are filtered to match the list of roles (comma separated) provided.
                  e.g roles=trustee,receptionist finds all trustee or receptionist vacancies.
                DESCRIPTION

      response "200", "returns the nearest vacancies to the specified location" do
        schema type: :object,
               properties: {
                 type: { type: :string, enum: %w[vacancies] },
                 list: { type: :array, items: BureauDetailsSchema::VACANCY_LIST_SCHEMA }
               },
               required: %w[type list],
               additionalProperties: false

        let(:local_authority) { LocalAuthority.create! id: "E05XXTEST", name: "Borsetshire" }

        let(:postcode) do
          Postcode.create! canonical: "FX1 7AA",
                           location: "POINT(-0.7731781431627129 52.03647020285301)",
                           local_authority_id: local_authority.id
        end

        let(:id) do
          # make a dummy office that gets ignored
          Office.create!(id: generate_salesforce_id,
                         name: "Citizens Advice Felpersham South",
                         office_type: :office,
                         location: "POINT(-0.7234629197151713, 52.05130183170279)",
                         volunteer_roles: [])

          office = Office.create!(id: generate_salesforce_id,
                                  name: "Citizens Advice Felpersham North",
                                  street: "14 Shakespeare Road",
                                  city: "Felpersham",
                                  postcode: "FX1 7QW",
                                  location: "POINT(-0.7646468 52.0451619)",
                                  legacy_id: 2,
                                  membership_number: "55/5555",
                                  office_type: :office,
                                  email: "felphersham@example.com",
                                  website: "http://www.felpershamcab.org.uk",
                                  phone: "01632 555 555",
                                  volunteer_roles: ["Receptionist", "Volunteer recruitment and support"],
                                  local_authority:)
          office.id
        end

        let(:near) { postcode.canonical }

        before { id }

        # rubocop:disable RSpec/ExampleLength
        run_test! do |response|
          expect(JSON.parse(response.body, symbolize_names: true)[:list]).to eq([{
            address: {
              address: "14 Shakespeare Road",
              town: "Felpersham",
              county: nil,
              postcode: "FX1 7QW",
              latLong: [52.0451619, -0.7646468]
            },
            distance: 0.7022914268464465,
            membershipNumber: "55/5555",
            name: "Citizens Advice Felpersham North",
            serialNumber: "2",
            email: "felphersham@example.com",
            id:,
            roles: [
              "Receptionist",
              "Volunteer recruitment and support"
            ],
            telephone: "01632 555 555",
            website: "http://www.felpershamcab.org.uk"
          }])
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end
  end
end
