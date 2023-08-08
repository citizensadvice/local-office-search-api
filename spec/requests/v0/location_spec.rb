# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Bureau Details legacy API - Locations", swagger_doc: "v0/swagger.yaml" do
  include_context "with episerver credentials"

  path "/api/v0/json/location/id/{serial_number}" do
    get "Show full details for a location" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :serial_number, in: :path, type: :string, description: "{serial_number} is the locations serial number."

      response "200", "fetches all data for an office" do
        schema BureauDetailsSchema::OFFICE_SCHEMA

        # this comes from the original fixture data provided in bureau-details
        # https://github.com/citizensadvice/rd-bureau-details-web-service/blob/master/BureauDetailsService/TestMember.cs
        let(:local_authority) { LocalAuthority.create! id: "E05XXTEST", name: "Borsetshire" }

        let(:member) do
          Office.new(id: generate_salesforce_id,
                     legacy_id: 1,
                     membership_number: "55/5555",
                     office_type: :member,
                     name: "Citizens Advice Felpersham",
                     company_number: "12345678",
                     charity_number: "87654321",
                     street: "14 Shakespeare Road",
                     city: "Felpersham",
                     postcode: "FX1 7QW",
                     location: "POINT(-0.7646468 52.0451619)",
                     local_authority:)
        end

        let(:office) do
          Office.new(id: generate_salesforce_id,
                     parent: member,
                     name: "Citizens Advice Felpersham North",
                     street: "14 Shakespeare Road",
                     city: "Felpersham",
                     postcode: "FX1 7QW",
                     location: "POINT(-0.7646468 52.0451619)",
                     legacy_id: 2,
                     membership_number: "55/5555",
                     office_type: :office,
                     about_text: "This is not a real Citizens Advice bureau.",
                     accessibility_information: ["Wheelchair accessible", "Wheelchair toilet access",
                                                 "Internet advice access"],
                     volunteer_roles: ["admin_and_customer_service"],
                     opening_hours_information: "Self help computers 9am to 4pm",
                     opening_hours_monday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(12, 30)),
                     opening_hours_tuesday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(12, 30)),
                     opening_hours_wednesday: Tod::Shift.new(Tod::TimeOfDay.new(13, 30), Tod::TimeOfDay.new(16)),
                     opening_hours_thursday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(16)),
                     opening_hours_friday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(16)),
                     telephone_advice_hours_monday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(16)),
                     telephone_advice_hours_tuesday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(16)),
                     telephone_advice_hours_wednesday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(16)),
                     telephone_advice_hours_thursday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(16)),
                     telephone_advice_hours_friday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(16)),
                     email: "felphersham@example.com",
                     website: "http://www.felpershamcab.org.uk",
                     phone: "01632 555 555",
                     local_authority:)
        end

        let(:serial_number) do
          office.legacy_id
        end

        before do
          member.save
          office.save
        end

        # rubocop:disable RSpec/ExampleLength
        run_test! do |response|
          expect(JSON.parse(response.body, symbolize_names: true)).to eq({
            address: {
              address: "14 Shakespeare Road",
              town: "Felpersham",
              county: nil,
              postcode: "FX1 7QW",
              onsDistrictCode: "E05XXTEST",
              localAuthority: "Borsetshire",
              latLong: [52.0451619, -0.7646468]
            },
            membershipNumber: "55/5555",
            name: "Citizens Advice Felpersham North",
            serialNumber: "2",
            inVCC: true,
            isBureau: true,
            isOutlet: false,
            features: [
              "Wheelchair accessible",
              "Wheelchair toilet access",
              "Internet advice access"
            ],
            notes: "This is not a real Citizens Advice bureau.",
            openingTimes: [
              {
                day: "Monday",
                start1: "10.00",
                end1: "12.30",
                start2: nil,
                end2: nil,
                notes: "Self help computers 9am to 4pm"
              },
              {
                day: "Tuesday",
                start1: "10.00",
                end1: "12.30",
                start2: nil,
                end2: nil,
                notes: "Self help computers 9am to 4pm"
              },
              {
                day: "Wednesday",
                start1: "13.30",
                end1: "16.00",
                start2: nil,
                end2: nil,
                notes: "Self help computers 9am to 4pm"
              },
              {
                day: "Thursday",
                start1: "10.00",
                end1: "16.00",
                start2: nil,
                end2: nil,
                notes: "Self help computers 9am to 4pm"
              },
              {
                day: "Friday",
                start1: "10.00",
                end1: "16.00",
                start2: nil,
                end2: nil,
                notes: "Self help computers 9am to 4pm"
              }
            ],
            publicContacts: {
              email: [
                {
                  contact: "felphersham@example.com",
                  description: nil
                }
              ],
              fax: [],
              minicom: [],
              telephone: [
                {
                  contact: "01632 555 555",
                  description: nil
                }
              ],
              website: [
                {
                  contact: "http://www.felpershamcab.org.uk",
                  description: nil
                }
              ]
            },
            telephoneTimes: [
              {
                day: "Monday",
                start1: "10.00",
                end1: "16.00",
                start2: nil,
                end2: nil,
                notes: nil
              },
              {
                day: "Tuesday",
                start1: "10.00",
                end1: "16.00",
                start2: nil,
                end2: nil,
                notes: nil
              },
              {
                day: "Wednesday",
                start1: "10.00",
                end1: "16.00",
                start2: nil,
                end2: nil,
                notes: nil
              },
              {
                day: "Thursday",
                start1: "10.00",
                end1: "16.00",
                start2: nil,
                end2: nil,
                notes: nil
              },
              {
                day: "Friday",
                start1: "10.00",
                end1: "16.00",
                start2: nil,
                end2: nil,
                notes: nil
              }
            ]
          })
        end
        # rubocop:enable RSpec/ExampleLength
      end

      response "404", "when no office with that serial number is found" do
        let(:serial_number) { "404" }

        run_test!
      end
    end
  end

  path "/api/v0/json/location/list" do
    get "List members" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :near, in: :query, type: :string, required: false,
                description: <<~DESCRIPTION.squish
                  If near is provided then the nearest locations to the value are returned. Locations are ordered so those
                  in the same local authority of are promoted.
                DESCRIPTION
      parameter name: :bureau, in: :query, type: :boolean, required: false, default: true,
                description: "If bureau is set to false then locations of type bureau will not be returned."
      parameter name: :outlet, in: :query, type: :boolean, required: false, default: false,
                description: "If outlet is set to true then outreaches will also be returned."

      response "501", "is a deprecated API which has not been reimplemented" do
        run_test!
      end
    end
  end
end
