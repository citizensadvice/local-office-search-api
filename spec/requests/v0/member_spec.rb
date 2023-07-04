# frozen_string_literal: true

require "swagger_helper"
require_relative "schema"

RSpec.describe "Bureau Details legacy API - Members", swagger_doc: "v0/swagger.yaml" do
  path "/api/v0/member/id/{id}" do
    get "Shows full details for a member" do
      produces "application/json"
      parameter name: :id, in: :path, type: :string,
                description: <<-DESCRIPTION.squish
                  {id} can be a serial number, eg 100002, or a membership number, eg 70/0023
                DESCRIPTION

      response "200", "fetches all data for a member" do
        schema BureauDetailsSchema::MEMBER_SCHEMA

        # this comes from the original fixture data provided in bureau-details
        # https://github.com/citizensadvice/rd-bureau-details-web-service/blob/master/BureauDetailsService/TestMember.cs
        let(:id) do
          member = Office.create! id: generate_salesforce_id,
                                  legacy_id: "x00001",
                                  membership_number: "55/5555",
                                  office_type: :member,
                                  name: "Felpersham Citizens Advice Bureau",
                                  company_number: "12345678",
                                  charity_number: "87654321",
                                  street: "14 Shakespeare Road",
                                  city: "Felpersham",
                                  postcode: "FX1 7QW",
                                  location: "POINT(-0.7646468 52.0451619)"

          office = Office.create! id: generate_salesforce_id,
                                  parent_id: member.id,
                                  name: "Citizens Advice Felpersham North",
                                  street: "14 Shakespeare Road",
                                  city: "Felpersham",
                                  postcode: "FX1 7QW",
                                  location: "POINT(-0.7646468 52.0451619)",
                                  legacy_id: "x00002",
                                  membership_number: "55/5555",
                                  office_type: :office,
                                  about_text: "This is not a real Citizens Advice bureau.",
                                  accessibility_information: ["Wheelchair accessible", "Wheelchair toilet access",
                                                              "Internet advice access"],
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
                                  phone: "01632 555 555"

          Office.create! id: generate_salesforce_id,
                         parent_id: office.id,
                         name: "Felpersham hospital",
                         street: "Felperham general hospital\nNorth Beck Street",
                         city: "Felpersham",
                         postcode: "FX1 7YT",
                         location: "POINT(-0.7361886 52.0257741)",
                         legacy_id: "x00004",
                         membership_number: "55/5555",
                         office_type: :outreach,
                         about_text: "This location does not exist.",
                         accessibility_information: ["Wheelchair accessible"],
                         opening_hours_thursday: Tod::Shift.new(Tod::TimeOfDay.new(10), Tod::TimeOfDay.new(14))

          member.membership_number
        end

        # rubocop:disable RSpec/ExampleLength
        run_test! do |response|
          expect(JSON.parse(response.body)).to eq({
            address: {
              address: "14 Shakespeare Road",
              town: "Felpersham",
              county: "Borsetshire",
              postcode: "FX1 7QW",
              onsDistrictCode: "00FX",
              localAuthority: "Borsetshire",
              latLong: [52.0451619, -0.7646468]
            },
            membershipNumber: "55/5555",
            name: "Citizens Advice Felpersham",
            serialNumber: "x00001",
            charityNumber: "87654321",
            companyNumber: "12345678",
            notes: nil,
            services: {
              bureaux: [
                {
                  address: {
                    address: "14 Shakespeare Road",
                    town: "Felpersham",
                    county: "Borsetshire",
                    postcode: "FX1 7QW",
                    onsDistrictCode: "00FX",
                    localAuthority: "Borsetshire",
                    latLong: [52.0451619, -0.7646468]
                  },
                  membershipNumber: "55/5555",
                  name: "Citizens Advice Felpersham North",
                  serialNumber: "x00002",
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
                      start1: "10.00",
                      end1: "12.30",
                      start2: nil,
                      end2: nil,
                      notes: "Self help computers 9am to 4pm"
                    },
                    {
                      day: "Thursday",
                      start1: "10.00",
                      end1: "12.30",
                      start2: nil,
                      end2: nil,
                      notes: "Self help computers 9am to 4pm"
                    },
                    {
                      day: "Friday",
                      start1: "10.00",
                      end1: "12.30",
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
                    fax: [
                      {
                        contact: "01632 555 500",
                        description: nil
                      }
                    ],
                    minicom: [
                      {
                        contact: "01632 555 600",
                        description: nil
                      }
                    ],
                    telephone: [
                      {
                        contact: "01632 555 555 (General advice)",
                        description: nil
                      },
                      {
                        contact: "01632 555 555 (Debt counselling service)",
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
                      day: "Wendesday",
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
                    county: "Borsetshire",
                    postcode: "FX1 7YT",
                    onsDistrictCode: "00FX",
                    localAuthority: "Borsetshire",
                    latLong: [
                      52.0257741,
                      -0.7361886
                    ]
                  },
                  membershipNumber: "55/5555",
                  name: "Felpersham hospital",
                  serialNumber: "x00004",
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
            vacancies: [],
            website: nil
          })
        end
        # rubocop:enable RSpec/ExampleLength
      end

      response "404", "when no member with that ID is found" do
        let(:id) { "404" }

        run_test!
      end
    end
  end

  path "/api/v0/member/list" do
    get "List members" do
      produces "application/json"
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
