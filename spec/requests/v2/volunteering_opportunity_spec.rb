# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Volunteering Opportunity API", swagger_doc: "v2/swagger.yaml" do
  path "/api/v2/volunteering-opportunities/{id}" do
    get "Retrieves a single volunteering opportunity" do
      produces "application/json"
      parameter name: :id, in: :path, type: :string

      response "200", "Shows the volunteering opportunities for the specified ID" do
        schema ApiV2Schema::VOLUNTEERING_OPPORTUNITY

        let(:office) do
          Office.new(id: generate_salesforce_id,
                     name: "Testtown Citizens Advice",
                     street: "62 West Wallaby Street",
                     city: "Wigan",
                     county: "Lancashire",
                     postcode: "WG1 1BH",
                     office_type: :office,
                     volunteer_roles: ["admin_and_customer_service"],
                     volunteer_recruitment_email: "volunteer@example.com")
        end

        let(:id) { office.id }

        before do
          office.save
        end

        # rubocop:disable RSpec/ExampleLength
        run_test! do |response|
          expect(JSON.parse(response.body)).to eq({
            id:,
            roles: ["admin_and_customer_service"],
            volunteer_recruitment_email: "volunteer@example.com",
            office: {
              id:,
              name: "Testtown Citizens Advice",
              type: "office",
              about_text: nil,
              accessibility_information: [],
              street: "62 West Wallaby Street",
              city: "Wigan",
              county: "Lancashire",
              postcode: "WG1 1BH",
              location: nil,
              email: nil,
              website: nil,
              phone: nil,
              allows_drop_ins: false,
              opening_hours: { monday: [], tuesday: [], wednesday: [], thursday: [], friday: [], saturday: [], sunday: [],
                               information: nil },
              telephone_advice_hours: { monday: [], tuesday: [], wednesday: [], thursday: [], friday: [], saturday: [], sunday: [],
                                        information: nil },
              relations: []
            }
          }.as_json)
        end
        # rubocop:enable RSpec/ExampleLength
      end

      response "404", "Office has no volunteering opportunities" do
        schema ApiV2Schema::JSON_PROBLEM

        let(:office) do
          Office.new(id: generate_salesforce_id,
                     name: "Citizens Advice Felpersham North",
                     street: "14 Shakespeare Road",
                     city: "Felpersham",
                     postcode: "FX1 7QW",
                     office_type: :office,
                     volunteer_roles: [])
        end

        let(:id) { office.id }

        before do
          office.save
        end

        run_test!
      end

      response "404", "No office with this ID" do
        schema ApiV2Schema::JSON_PROBLEM

        let(:id) { generate_salesforce_id }

        run_test!
      end
    end
  end
end
