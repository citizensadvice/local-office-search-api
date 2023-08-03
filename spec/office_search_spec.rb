# frozen_string_literal: true

require "rails_helper"
require "office_search"

RSpec.describe OfficeSearch do
  it "only returns LCAs in the area when specified" do
    in_area_office = create_office_with_local_authority
    create_office_with_local_authority "X0001235", "Testtown"
    create_postcode "XX4 6LA", in_area_office.local_authority_id

    results, = described_class.by_location("XX4 6LA", only_in_same_local_authority: true)

    expect(results.pluck(:id)).to contain_exactly(in_area_office.id)
  end

  it "returns all the LCAs in an area when it's a fuzzy match that matches on local authority names" do
    office = create_office_with_local_authority
    other_office = create_office name: "Another Citizens Advice", local_authority_id: office.local_authority_id

    results, = described_class.by_location("test")

    expect(results.pluck(:id)).to contain_exactly(office.id, other_office.id)
  end

  it "returns all LCAs which have a fuzzy match on the LCA name" do
    office = create_office_with_local_authority
    other_office = create_office name: "Anotherville Citizens Advice", local_authority_id: office.local_authority_id

    results, = described_class.by_location("anotherville")

    expect(results.pluck(:id)).to contain_exactly(other_office.id)
  end

  it "returns both a mix of if the office name matches and if the local authority matches" do
    office = create_office_with_local_authority
    other_office = create_office name: "Testtown Citizens Advice"

    results, = described_class.by_location("test")

    expect(results.pluck(:id)).to contain_exactly(office.id, other_office.id)
  end

  it "ensures fuzzy matches respect the only with vacancies flag" do
    office = create_office_with_local_authority
    office_with_roles = create_office name: "Another Citizens Advice", local_authority_id: office.local_authority_id,
                                      volunteer_roles: ["trustee"]

    results, = described_class.by_location("test", only_with_vacancies: true)

    expect(results.pluck(:id)).to contain_exactly(office_with_roles.id)
  end

  def create_office_with_local_authority(la_id = "X0001234", la_name = "Testshire")
    local_authority_id = LocalAuthority.create!(id: la_id, name: la_name).id
    create_office name: "#{la_name} Citizens Advice", local_authority_id:
  end

  def create_office(vals = {})
    Office.create!({ id: generate_salesforce_id, office_type: :office, name: "Testtown Citizens Advice" }.update(vals))
  end

  def create_postcode(canonical, local_authority_id = "X0001234")
    Postcode.create! canonical:, local_authority_id:, location: "POINT(-0.78 52.66)"
  end
end
