# frozen_string_literal: true

require "rails_helper"
require "lss_loader"
require "csv"

RSpec.describe LssLoader do
  it "removes any offices no longer referenced in the data" do
    id = SecureRandom.hex(9)
    Office.create! id:, name: "Testtown Citizens Advice", office_type: "member"

    load_from_fixtures "single", "empty"

    expect(Office.all.map(&:id)).not_to include id
  end

  it "does not remove any offices if an error occurs during load" do
    id = SecureRandom.hex(9)
    Office.create! id:, name: "Testtown Citizens Advice", office_type: "member"

    load_from_fixtures_with_error "corrupt", "empty"

    expect(Office.all.map(&:id)).to eq [id]
  end

  def load_from_fixtures(account_csv, opening_hours_csv)
    LssLoader.update_offices CSV.read(File.expand_path("../fixtures/accounts/#{account_csv}.csv", File.dirname(__FILE__)), headers: true),
                             CSV.read(File.expand_path("../fixtures/opening_hours/#{opening_hours_csv}.csv", File.dirname(__FILE__)),
                                      headers: true)
  end

  def load_from_fixtures_with_error(account_csv, opening_hours_csv)
    expect do
      load_from_fixtures account_csv, opening_hours_csv
    end.to raise_error LssLoader::LssLoadError
  end
end
