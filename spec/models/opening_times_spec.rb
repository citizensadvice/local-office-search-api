# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpeningTimes do
  it "can correctly serialise opening times" do
    office = Office.create(id: generate_salesforce_id, name: "Testtown Citizens Advice", office_type: "member")

    described_class.create! office_id: office.id, day_of_week: "monday", opening_time_for: "office",
                            range: Tod::Shift.new(Tod::TimeOfDay.new(9), Tod::TimeOfDay.new(17))

    opening_time = described_class.first
    expect(opening_time.range).to eq Tod::Shift.new(Tod::TimeOfDay.new(9), Tod::TimeOfDay.new(17))
  end
end
