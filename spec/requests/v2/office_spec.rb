# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Lookup Local Office API" do
  path "/api/v2/offices/{id}" do
    get "Retrieves a single office" do
      produces "application/json"
      parameter name: :id, in: :path, type: :string

      response "200", "Fetches a single office" do
        schema ApiV2Schema::OFFICE

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
            allows_drop_ins: true,
            opening_hours_information: "Sessions available between the following times",
            telephone_advice_hours_information: "Please phone us"
          }).id
        end

        before do
          OpeningTimes.create(office_id: id, day_of_week: "monday", opening_time_for: "office",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(1), Tod::TimeOfDay.new(1, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "monday", opening_time_for: "office",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(15), Tod::TimeOfDay.new(15, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "tuesday", opening_time_for: "office",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(2), Tod::TimeOfDay.new(2, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "wednesday", opening_time_for: "office",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(3), Tod::TimeOfDay.new(3, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "thursday", opening_time_for: "office",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(4), Tod::TimeOfDay.new(4, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "friday", opening_time_for: "office",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(5), Tod::TimeOfDay.new(5, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "saturday", opening_time_for: "office",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(6), Tod::TimeOfDay.new(6, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "sunday", opening_time_for: "office",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(7), Tod::TimeOfDay.new(7, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "monday", opening_time_for: "telephone",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(8), Tod::TimeOfDay.new(8, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "tuesday", opening_time_for: "telephone",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(9), Tod::TimeOfDay.new(9, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "wednesday", opening_time_for: "telephone",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(10, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "thursday", opening_time_for: "telephone",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(11), Tod::TimeOfDay.new(11, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "friday", opening_time_for: "telephone",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(12), Tod::TimeOfDay.new(12, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "saturday", opening_time_for: "telephone",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(13), Tod::TimeOfDay.new(13, 30)))
          OpeningTimes.create(office_id: id, day_of_week: "sunday", opening_time_for: "telephone",
                              range: Tod::Shift.new(Tod::TimeOfDay.new(14), Tod::TimeOfDay.new(14, 30)))
        end

        # rubocop:disable RSpec/ExampleLength
        run_test! do |response|
          expect(JSON.parse(response.body)).to eq({
            id:,
            name: "Testtown Citizens Advice",
            type: "office",
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
            allows_drop_ins: true,
            opening_hours: {
              information: "Sessions available between the following times",
              monday: [{ opens: "01:00:00", closes: "01:30:00" }, { opens: "15:00:00", closes: "15:30:00" }],
              tuesday: [{ opens: "02:00:00", closes: "02:30:00" }],
              wednesday: [{ opens: "03:00:00", closes: "03:30:00" }],
              thursday: [{ opens: "04:00:00", closes: "04:30:00" }],
              friday: [{ opens: "05:00:00", closes: "05:30:00" }],
              saturday: [{ opens: "06:00:00", closes: "06:30:00" }],
              sunday: [{ opens: "07:00:00", closes: "07:30:00" }]
            },
            telephone_advice_hours: {
              information: "Please phone us",
              monday: [{ opens: "08:00:00", closes: "08:30:00" }],
              tuesday: [{ opens: "09:00:00", closes: "09:30:00" }],
              wednesday: [{ opens: "10:00:00", closes: "10:30:00" }],
              thursday: [{ opens: "11:00:00", closes: "11:30:00" }],
              friday: [{ opens: "12:00:00", closes: "12:30:00" }],
              saturday: [{ opens: "13:00:00", closes: "13:30:00" }],
              sunday: [{ opens: "14:00:00", closes: "14:30:00" }]
            },
            relations: [
              {
                id: parent.id,
                type: "member",
                name: parent.name
              }
            ]
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
          expect(response.location).to eq("http://www.example.com/api/v2/offices/#{office.id}")
        end
      end

      response "404", "No office with this ID" do
        schema ApiV2Schema::JSON_PROBLEM

        let(:id) { generate_salesforce_id }

        run_test!
      end
    end
  end
end
