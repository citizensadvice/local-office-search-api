# frozen_string_literal: true

require "rails_helper"

RSpec.describe Office do
  it "can save and fetch a minimal example" do
    id = generate_salesforce_id

    described_class.create! id:, name: "Testtown Citizens Advice", office_type: "member"

    fetched_office = described_class.find id
    expect(fetched_office.name).to eq "Testtown Citizens Advice"
  end

  it "can correctly serialise opening times" do
    id = generate_salesforce_id

    described_class.create! id:, name: "Testtown Citizens Advice", office_type: "member",
                            opening_hours_monday: Tod::Shift.new(Tod::TimeOfDay.new(9), Tod::TimeOfDay.new(17))

    fetched_office = described_class.find id
    expect(fetched_office.opening_hours_monday).to eq Tod::Shift.new(Tod::TimeOfDay.new(9), Tod::TimeOfDay.new(17))
  end
end
