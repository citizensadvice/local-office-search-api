# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Bureau Details legacy API - Members", swagger_doc: "v0/swagger.yaml" do
  include_context "with episerver credentials"

  path "/api/v0/json/member/id/{id}" do
    get "Shows full details for a member" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :id, in: :path, type: :string,
                description: <<-DESCRIPTION.squish
                  {id} can be a serial number, eg 100002, or a membership number, eg 70/0023
                DESCRIPTION

      response "200", "fetches all data for a member" do
        schema BureauDetailsSchema::MEMBER_SCHEMA

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

        let(:outlet) do
          Office.new(id: generate_salesforce_id,
                     parent: office,
                     name: "Felpersham hospital",
                     street: "Felperham general hospital\nNorth Beck Street",
                     city: "Felpersham",
                     postcode: "FX1 7YT",
                     location: "POINT(-0.7361886 52.0257741)",
                     legacy_id: 4,
                     membership_number: "55/5555",
                     office_type: :outreach,
                     about_text: "This location does not exist.",
                     accessibility_information: ["Wheelchair accessible"],
                     opening_hours_thursday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(14)),
                     local_authority:)
        end

        let(:id) do
          member.membership_number
        end

        before do
          member.save
          office.save
          outlet.save
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
            name: "Citizens Advice Felpersham",
            serialNumber: "1",
            charityNumber: "87654321",
            companyNumber: "12345678",
            notes: nil,
            services: {
              bureaux: [
                {
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
                }
              ],
              outlets: [
                {
                  address: {
                    address: "Felperham general hospital\nNorth Beck Street",
                    town: "Felpersham",
                    county: nil,
                    postcode: "FX1 7YT",
                    onsDistrictCode: "E05XXTEST",
                    localAuthority: "Borsetshire",
                    latLong: [
                      52.0257741,
                      -0.7361886
                    ]
                  },
                  membershipNumber: "55/5555",
                  name: "Felpersham hospital",
                  serialNumber: "4",
                  inVCC: false,
                  isBureau: false,
                  isOutlet: true,
                  features: [
                    "Wheelchair accessible"
                  ],
                  notes: "This location does not exist.",
                  openingTimes: [
                    {
                      day: "Thursday",
                      start1: "10.00",
                      end1: "14.00",
                      start2: nil,
                      end2: nil,
                      notes: nil
                    }
                  ],
                  publicContacts: {
                    email: [],
                    fax: [],
                    minicom: [],
                    telephone: [],
                    website: []
                  },
                  telephoneTimes: []
                }
              ]
            },
            staff: nil,
            vacancies: [{
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
              id: office.id,
              roles: ["Admin and customer service"],
              telephone: "01632 555 555",
              website: "http://www.felpershamcab.org.uk"
            }],
            website: nil
          })
        end
        # rubocop:enable RSpec/ExampleLength

        context "when the location is null" do
          before do
            member.update! location: nil
          end

          run_test! do |response|
            body = JSON.parse(response.body, symbolize_names: true)
            expect(body[:address][:latLong]).to eq [0.0, 0.0]
          end
        end

        context "when the outlet is associated using salesforce IDs, not membership number" do
          let(:outlet) do
            Office.new(id: generate_salesforce_id,
                       parent: office,
                       membership_number: "66/6666",
                       name: "Felpersham hospital",
                       street: "North Beck Street",
                       city: "Felpersham",
                       office_type: :outreach,
                       local_authority:)
          end

          run_test! do |response|
            body = JSON.parse(response.body, symbolize_names: true)
            expect(body[:services][:outlets].count).to eq 1
          end
        end
      end

      response "404", "when no member with that ID is found" do
        let(:id) { "404" }

        run_test!
      end
    end
  end

  path "/api/v0/json/member/list" do
    get "List members" do
      produces "application/json"
      security [basic_auth: []]
      parameter name: :near, in: :query, type: :string, required: false,
                description: <<~DESCRIPTION.squish
                  Without near all members will be show in alphabetical order. If near is provided then the nearest
                  members to the parameter will be returned.
                DESCRIPTION

      response "501", "is a deprecated API which has not been reimplemented" do
        run_test!
      end
    end
  end
end
