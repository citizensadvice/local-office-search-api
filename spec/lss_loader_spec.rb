# frozen_string_literal: true

require "rails_helper"
require "lss_loader"
require "csv"

RSpec.describe LssLoader do
  it "removes any offices no longer referenced in the data" do
    id = create_a_single_office

    load_from_fixtures locations_csv_filename: "minimal"

    expect(Office.all.map(&:id)).not_to include id
  end

  it "does not remove any offices if an error occurs during load" do
    id = create_a_single_office

    load_from_fixtures_with_error locations_csv_filename: "corrupt"

    expect(Office.all.map(&:id)).to eq [id]
  end

  it "loads a single advice location record into the database with minimal fields" do
    load_from_fixtures locations_csv_filename: "minimal"

    expect_single_record id: "0014K000009EMMbQAO",
                         name: "Citizens Advice Bristol",
                         office_type: "office"
  end

  # rubocop:disable RSpec/ExampleLength
  it "loads a single advice location record into the database with all text fields populated" do
    load_from_fixtures locations_csv_filename: "all_strings_populated"

    expect_single_record id: "0014K000009EMMbQAO",
                         name: "Citizens Advice Bristol",
                         office_type: "office",
                         legacy_id: 101_185,
                         membership_number: "90/0011",
                         about_text: "About our advice service",
                         accessibility_information: [],
                         street: "48 Fairfax Street",
                         city: "BRISTOL",
                         county: "Bristol",
                         postcode: "BS1 3BL",
                         email: "cab@example.com",
                         website: "https://www.example.com/",
                         phone: "0181 811 8181",
                         opening_hours_information: "We are open for drop-ins",
                         telephone_advice_hours_information: "Please call to book an appointment"
  end
  # rubocop:enable RSpec/ExampleLength

  it "handles multiline strings in the source file correctly" do
    load_from_fixtures locations_csv_filename: "multiline"

    expect(Office.first.about_text).to eq "This detail is on\nMultiple lines."
  end

  it "handles location information correctly" do
    load_from_fixtures locations_csv_filename: "has_location"

    # Think the lat and lon look backwards? that's because in GIS coordinates are expressed in
    # x,y terms, not lat, lon. Therefore the lon comes first.
    expect(Office.first.location.as_text).to eq "POINT (1.18184 51.07988)"
  end

  it "loads in accessibility information" do
    load_from_fixtures locations_csv_filename: "minimal", accessibility_info_csv_filename: "minimal"

    expect(Office.first.accessibility_information).to eq %w[has_wheelchair_access has_induction_loop]
  end

  it "loads in volunteer roles as list" do
    load_from_fixtures locations_csv_filename: "minimal", volunteer_roles_csv_filename: "minimal"

    expect(Office.first.volunteer_roles).to eq ["admin_and_customer_service", "giving_information_advice_and_client support", "trustee"]
  end

  # rubocop:disable RSpec/ExampleLength
  it "correctly assigns telephone and opening hours" do
    nine_to_five = Tod::Shift.new(Tod::TimeOfDay.new(9, 0), Tod::TimeOfDay.new(17, 0))
    load_from_fixtures locations_csv_filename: "minimal", opening_hours_csv_filename: "minimal"

    expect_single_record id: "0014K000009EMMbQAO",
                         name: "Citizens Advice Bristol",
                         office_type: "office",
                         opening_hours_monday: nil,
                         opening_hours_tuesday: nil,
                         opening_hours_wednesday: nil,
                         opening_hours_thursday: nil,
                         opening_hours_friday: nil,
                         opening_hours_saturday: nine_to_five,
                         opening_hours_sunday: nine_to_five,
                         telephone_advice_hours_monday: nine_to_five,
                         telephone_advice_hours_tuesday: nine_to_five,
                         telephone_advice_hours_wednesday: nine_to_five,
                         telephone_advice_hours_thursday: nine_to_five,
                         telephone_advice_hours_friday: nine_to_five,
                         telephone_advice_hours_saturday: nil,
                         telephone_advice_hours_sunday: nil
  end
  # rubocop:enable RSpec/ExampleLength

  it "ignores opening hours where it closes before it opens" do
    load_from_fixtures locations_csv_filename: "minimal", opening_hours_csv_filename: "includes_time_travel"

    expect_single_record id: "0014K000009EMMbQAO", name: "Citizens Advice Bristol", office_type: "office"
  end

  it "sets up parent/child hierarchy correctly" do
    load_from_fixtures locations_csv_filename: "basic_hierarchy"

    expect_basic_hierarchy
  end

  it "handles when a child is defined before a parent in the CSV files" do
    load_from_fixtures locations_csv_filename: "backwards_hierarchy"

    expect_basic_hierarchy
  end

  it "makes a dangling parent ID null" do
    load_from_fixtures locations_csv_filename: "dangling_hierarchy"

    expect(Office.find("0014K00000an3g3QAA").parent_id).to be_nil
  end

  it "loads in local authority IDs on advice locations" do
    LocalAuthority.create! id: "E06000023", name: "Bristol, City of"
    load_from_fixtures locations_csv_filename: "has_local_authority"

    expect(Office.find("0014K000009EMMbQAO").local_authority_id).to eq("E06000023")
  end

  # rubocop:disable RSpec/ExampleLength
  it "loads in members from the members file" do
    LocalAuthority.create! id: "E07000112", name: "Folkestone and Hythe"
    load_from_fixtures members_csv_filename: "minimal"

    expect_single_record id: "0014K00000PcC94QAF",
                         name: "Citizens Advice Shepway",
                         office_type: "member",
                         charity_number: "1102964",
                         company_number: "5063463",
                         legacy_id: 100_725,
                         membership_number: "75/0030",
                         street: "Units 4 - 6, Princes Gate, George Lane,",
                         city: "FOLKESTONE",
                         county: "Kent",
                         postcode: "CT20 1RH",
                         email: "cab@example.com",
                         website: "www.shepwaycab.co.uk",
                         local_authority_id: "E07000112"
  end
  # rubocop:enable RSpec/ExampleLength

  it "makes a dangling local authority ID null" do
    load_from_fixtures members_csv_filename: "minimal"

    expect(Office.find("0014K00000PcC94QAF").local_authority_id).to be_nil
  end

  def create_a_single_office
    id = SecureRandom.hex(9)
    Office.create! id:, name: "Testtown Citizens Advice", office_type: "member"
    id
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def load_from_fixtures(members_csv_filename: "empty", locations_csv_filename: "empty", opening_hours_csv_filename: "empty",
                         accessibility_info_csv_filename: "empty", volunteer_roles_csv_filename: "empty")
    members_csv = File.open(File.expand_path("fixtures/members/#{members_csv_filename}.csv", File.dirname(__FILE__)))
    advice_locations_csv = File.open(File.expand_path("fixtures/advice_locations/#{locations_csv_filename}.csv", File.dirname(__FILE__)))
    opening_hours_csv = File.open(File.expand_path("fixtures/opening_hours/#{opening_hours_csv_filename}.csv", File.dirname(__FILE__)))
    accessibility_info_csv = File.open(
      File.expand_path("fixtures/accessibility_info/#{accessibility_info_csv_filename}.csv", File.dirname(__FILE__))
    )
    volunteer_roles_csv = File.open(
      File.expand_path("fixtures/volunteer_roles/#{volunteer_roles_csv_filename}.csv", File.dirname(__FILE__))
    )
    lss_loader = LssLoader::LssLoader.new(members_csv:,
                                          advice_locations_csv:,
                                          opening_hours_csv:,
                                          accessibility_info_csv:,
                                          volunteer_roles_csv:)
    lss_loader.load!
  ensure
    members_csv&.close
    advice_locations_csv&.close
    opening_hours_csv&.close
    accessibility_info_csv&.close
    volunteer_roles_csv&.close
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def load_from_fixtures_with_error(**opts)
    expect do
      load_from_fixtures(**opts)
    end.to raise_error LssLoader::LssLoadError
  end

  def expect_single_record(vals)
    vals = {
      parent_id: nil,
      local_authority_id: nil,
      legacy_id: nil,
      membership_number: nil,
      company_number: nil,
      charity_number: nil,
      about_text: nil,
      accessibility_information: [],
      street: nil,
      city: nil,
      county: nil,
      postcode: nil,
      location: nil,
      email: nil,
      website: nil,
      phone: nil,
      opening_hours_information: nil,
      allows_drop_ins: false,
      opening_hours_monday: nil,
      opening_hours_tuesday: nil,
      opening_hours_wednesday: nil,
      opening_hours_thursday: nil,
      opening_hours_friday: nil,
      opening_hours_saturday: nil,
      opening_hours_sunday: nil,
      telephone_advice_hours_information: nil,
      telephone_advice_hours_monday: nil,
      telephone_advice_hours_tuesday: nil,
      telephone_advice_hours_wednesday: nil,
      telephone_advice_hours_thursday: nil,
      telephone_advice_hours_friday: nil,
      telephone_advice_hours_saturday: nil,
      telephone_advice_hours_sunday: nil,
      volunteer_recruitment_email: nil,
      volunteer_roles: []
    }.update(vals)

    expect(Office.first.serializable_hash.symbolize_keys).to eq vals
  end

  def expect_basic_hierarchy
    expect(Office.find("0014K00000PcCBSQA3").parent_id).to be_nil
    expect(Office.find("0014K000009EMQ2QAO").parent_id).to eq "0014K00000PcCBSQA3"
    expect(Office.find("0014K00000fFpE2QAK").parent_id).to eq "0014K000009EMQ2QAO"
  end
end
