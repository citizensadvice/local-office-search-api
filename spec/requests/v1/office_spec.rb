# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Lookup Local Office API" do
  path "/api/v1/offices/{id}" do
    get "Retrieves a single office" do
      produces "application/json"
      parameter name: :id, in: :path, type: :string

      response "200", "Fetches a single office" do
        nullable_string = %i[string null]

        geo_json_point = {
          "$id": "https://geojson.org/schema/Point.json",
          type: :object,
          properties: {
            type: { type: :string, enum: ["Point"] },
            coordinates: { type: :array, items: { type: :number }, minItems: 2, maxItems: 2 }
          },
          required: %w[type coordinates],
          additionalProperties: false
        }

        time_of_day = {
          type: :string,
          pattern: '^\d{2}:\d{2}:\d{2}$'
        }

        time_range = {
          type: :object,
          properties: { opens: time_of_day, closes: time_of_day },
          required: %w[opens closes],
          additionalProperties: false
        }
        nullable_time_range = [:null, time_range]

        opening_hours_specification = {
          type: :object,
          properties: {
            information: { type: nullable_string },
            monday: { type: nullable_time_range },
            tuesday: { type: nullable_time_range },
            wednesday: { type: nullable_time_range },
            thursday: { type: nullable_time_range },
            friday: { type: nullable_time_range },
            saturday: { type: nullable_time_range },
            sunday: { type: nullable_time_range }
          },
          required: %w[information monday tuesday wednesday thursday friday saturday sunday],
          additionalProperties: false
        }

        schema "$schema": "https://json-schema.org/draft/2019-09/schema",
               "$id": "https://local-office-search.citizensadvice.org.uk/schemas/v1/office",
               type: :object,
               properties: {
                 id: { type: :string },
                 member_id: { type: nullable_string },
                 name: { type: :string },
                 about_text: { type: nullable_string },
                 accessibility_information: { type: :array, items: { type: :string } },
                 street: { type: nullable_string },
                 city: { type: nullable_string },
                 county: { type: nullable_string },
                 postcode: { type: nullable_string },
                 location: { type: [:null, geo_json_point] },
                 email: { type: nullable_string },
                 website: { type: nullable_string },
                 phone: { type: nullable_string },
                 opening_hours: opening_hours_specification,
                 telephone_advice_hours: opening_hours_specification
               },
               required: %i[id member_id name about_text accessibility_information street city postcode location email website phone
                            opening_hours telephone_advice_hours],
               additionalProperties: false

        let(:parent) do
          Office.create({ id: generate_salesforce_id, office_type: :member, name: "Testtown CAB" })
        end

        let(:id) do
          Office.create({
            id: generate_salesforce_id,
            parent_id: parent.id,
            office_type: :office,
            name: "Testtown Citizens Advice",
            about_text: "Open for drop-ins",
            accessibility_information: ["Wheelchair accessible"],
            street: "62 West Wallaby Street",
            city: "Wigan",
            county: "Lancashire",
            postcode: "WG1 1BH",
            location: "POINT(-2.692674 53.5373075)",
            email: "contact@wigancitizensadvice.org.uk",
            website: "https://www.wigancitizensadvice.org.uk/",
            phone: "01234 567890",
            opening_hours_information: "Sessions available between the following times",
            opening_hours_monday: Tod::Shift.new(Tod::TimeOfDay.new(1), Tod::TimeOfDay.new(1, 30)),
            opening_hours_tuesday: Tod::Shift.new(Tod::TimeOfDay.new(2), Tod::TimeOfDay.new(2, 30)),
            opening_hours_wednesday: Tod::Shift.new(Tod::TimeOfDay.new(3), Tod::TimeOfDay.new(3, 30)),
            opening_hours_thursday: Tod::Shift.new(Tod::TimeOfDay.new(4), Tod::TimeOfDay.new(4, 30)),
            opening_hours_friday: Tod::Shift.new(Tod::TimeOfDay.new(5), Tod::TimeOfDay.new(5, 30)),
            opening_hours_saturday: Tod::Shift.new(Tod::TimeOfDay.new(6), Tod::TimeOfDay.new(6, 30)),
            opening_hours_sunday: Tod::Shift.new(Tod::TimeOfDay.new(7), Tod::TimeOfDay.new(7, 30)),
            telephone_advice_hours_information: "Please phone us",
            telephone_advice_hours_monday: Tod::Shift.new(Tod::TimeOfDay.new(8), Tod::TimeOfDay.new(8, 30)),
            telephone_advice_hours_tuesday: Tod::Shift.new(Tod::TimeOfDay.new(9), Tod::TimeOfDay.new(9, 30)),
            telephone_advice_hours_wednesday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(10, 30)),
            telephone_advice_hours_thursday: Tod::Shift.new(Tod::TimeOfDay.new(11), Tod::TimeOfDay.new(11, 30)),
            telephone_advice_hours_friday: Tod::Shift.new(Tod::TimeOfDay.new(12), Tod::TimeOfDay.new(12, 30)),
            telephone_advice_hours_saturday: Tod::Shift.new(Tod::TimeOfDay.new(13), Tod::TimeOfDay.new(13, 30)),
            telephone_advice_hours_sunday: Tod::Shift.new(Tod::TimeOfDay.new(14), Tod::TimeOfDay.new(14, 30))
          }).id
        end

        # rubocop:disable RSpec/ExampleLength
        run_test! do |response|
          expect(JSON.parse(response.body)).to eq({
            id:,
            member_id: parent.id,
            name: "Testtown Citizens Advice",
            about_text: "Open for drop-ins",
            accessibility_information: ["Wheelchair accessible"],
            street: "62 West Wallaby Street",
            city: "Wigan",
            county: "Lancashire",
            postcode: "WG1 1BH",
            location: { type: "Point", coordinates: [-2.692674, 53.5373075] },
            email: "contact@wigancitizensadvice.org.uk",
            website: "https://www.wigancitizensadvice.org.uk/",
            phone: "01234 567890",
            opening_hours: {
              information: "Sessions available between the following times",
              monday: { opens: "01:00:00", closes: "01:30:00" },
              tuesday: { opens: "02:00:00", closes: "02:30:00" },
              wednesday: { opens: "03:00:00", closes: "03:30:00" },
              thursday: { opens: "04:00:00", closes: "04:30:00" },
              friday: { opens: "05:00:00", closes: "05:30:00" },
              saturday: { opens: "06:00:00", closes: "06:30:00" },
              sunday: { opens: "07:00:00", closes: "07:30:00" }
            },
            telephone_advice_hours: {
              information: "Please phone us",
              monday: { opens: "08:00:00", closes: "08:30:00" },
              tuesday: { opens: "09:00:00", closes: "09:30:00" },
              wednesday: { opens: "10:00:00", closes: "10:30:00" },
              thursday: { opens: "11:00:00", closes: "11:30:00" },
              friday: { opens: "12:00:00", closes: "12:30:00" },
              saturday: { opens: "13:00:00", closes: "13:30:00" },
              sunday: { opens: "14:00:00", closes: "14:30:00" }
            }
          }.as_json)
        end
        # rubocop:enable RSpec/ExampleLength
      end

      response "302", "Allows you to look up an office by its resource directory ID and redirect to canonical ID" do
        let(:office) do
          Office.create({ id: generate_salesforce_id, office_type: :office, name: "Testtown CAB", legacy_id: 1234 })
        end
        let(:id) { office.legacy_id }

        run_test! do |response|
          expect(response.location).to eq("http://www.example.com/api/v1/offices/#{office.id}")
        end
      end

      response "404", "No office with this ID" do
        schema ApiV1Schema::JSON_PROBLEM

        let(:id) { generate_salesforce_id }

        run_test!
      end
    end
  end
end
