# frozen_string_literal: true

require "rails_helper"

RSpec.describe Office do
  it "can round trip to the database" do
    salesforce_id = "abcdefgh0123456789"
    Office.create! id: salesforce_id, name: "Testtown Citizens Advice", office_type: "member"
    fetched_office = Office.find salesforce_id
    expect(fetched_office.name).to eq "Testtown Citizens Advice"
  end
end
