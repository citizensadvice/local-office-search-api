# frozen_string_literal: true

require "rails_helper"
require "lss_loader"
require "csv"

RSpec.describe LssLoader do
  it "removes any offices no longer referenced in the data" do
    id = create_a_single_office

    load_from_fixtures "minimal", "empty"

    expect(Office.all.map(&:id)).not_to include id
  end

  it "does not remove any offices if an error occurs during load" do
    id = create_a_single_office

    load_from_fixtures_with_error "corrupt", "empty"

    expect(Office.all.map(&:id)).to eq [id]
  end

  it "loads a single record into the database with minimal fields" do
    load_from_fixtures "minimal", "empty"

    expect_single_record id: "0014K00000PcCA6QAN",
                         name: "Citizens Advice Bristol",
                         office_type: "member"
  end

  # rubocop:disable RSpec/ExampleLength
  it "loads a single record into the database with all text fields populated" do
    load_from_fixtures "all_strings_populated", "empty"

    expect_single_record id: "0014K00000PcCA6QAN",
                         name: "Citizens Advice Bristol",
                         office_type: "office",
                         legacy_id: 101_185,
                         about_text: "About our advice service",
                         accessibility_information: [],
                         street: "48 Fairfax Street",
                         city: "BRISTOL",
                         postcode: "BS1 3BL",
                         email: "cab@example.com",
                         website: "https://www.example.com/",
                         phone: "0181 811 8181",
                         opening_hours_information: "We are open for drop-ins",
                         telephone_advice_hours_information: "Please call to book an appointment"
  end
  # rubocop:enable RSpec/ExampleLength

  it "handles multiline strings in the source file correctly" do
    load_from_fixtures "multiline", "empty"

    expect(Office.first.about_text).to eq "This detail is on\nMultiple lines."
  end

  it "handles location information correctly" do
    load_from_fixtures "has_location", "empty"

    # Think the lat and lon look backwards? that's because in GIS coordinates are expressed in
    # x,y terms, not lat, lon. Therefore the lon comes first.
    expect(Office.first.location).to eq RGeo::Cartesian.preferred_factory.point(1.18184, 51.07988)
  end

  it "loads in accessibility information as list"
  it "correctly assigns telephone and opening hour numbers"

  def create_a_single_office
    id = SecureRandom.hex(9)
    Office.create! id:, name: "Testtown Citizens Advice", office_type: "member"
    id
  end

  def load_from_fixtures(account_csv, opening_hours_csv)
    lss_loader = LssLoader.new CSV.read(File.expand_path("../fixtures/accounts/#{account_csv}.csv", File.dirname(__FILE__)), headers: true),
                               CSV.read(File.expand_path("../fixtures/opening_hours/#{opening_hours_csv}.csv", File.dirname(__FILE__)),
                                        headers: true)
    lss_loader.load!
  end

  def load_from_fixtures_with_error(account_csv, opening_hours_csv)
    expect do
      load_from_fixtures account_csv, opening_hours_csv
    end.to raise_error LssLoader::LssLoadError
  end

  def expect_single_record(vals)
    vals = {
      parent_id: nil,
      legacy_id: nil,
      about_text: nil,
      accessibility_information: [],
      street: nil,
      city: nil,
      postcode: nil,
      location: nil,
      email: nil,
      website: nil,
      phone: nil,
      opening_hours_information: nil,
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
      telephone_advice_hours_sunday: nil
    }.update(vals)

    expect(Office.first.attributes.symbolize_keys).to eq vals
  end
end
