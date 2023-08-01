# frozen_string_literal: true

require "rails_helper"
require "postcode_loader"
require "csv"

RSpec.describe PostcodeLoader do
  # rubocop:disable RSpec/MultipleExpectations - it makes sense to check all the fields together as it's a distinct piece of functionality
  it "loads a single postcode" do
    load_from_fixture "single"

    postcode = Postcode.first
    expect(postcode.canonical).to eq("AB1 0AA")
    expect(postcode.local_authority_id).to eq("S12000033")
    expect(postcode.location.to_s).to eq("POINT (-2.242851 57.101474)")
  end
  # rubocop:enable RSpec/MultipleExpectations

  it "skips postcodes which are not assigned to a local authority" do
    load_from_fixture "with_nil_la"

    expect(Postcode.count).to eq(1)
  end

  it "is idempotent when importing postcodes" do
    load_from_fixture "single"
    initial_id = Postcode.first.id
    load_from_fixture "single"

    expect(Postcode.all.map(&:id)).to eq([initial_id])
  end

  describe "local authority handling" do
    it "loads a single local authority" do
      load_from_fixture "single"

      expect(LocalAuthority.first.serializable_hash.symbolize_keys).to eq({ id: "S12000033", name: "Aberdeen City" })
    end

    it "removes local authorities that are no longer there" do
      LocalAuthority.create! id: "X00000000", name: "Testtown City Council"
      load_from_fixture "single"

      expect(LocalAuthority.find_by(id: "X00000000")).to be_nil
    end

    it "does nothing if the file is corrupt" do
      LocalAuthority.create! id: "X00000000", name: "Testtown City Council"

      load_from_fixture_with_error "corrupt"
      expect(LocalAuthority.find_by(id: "X00000000")).not_to be_nil
    end

    it "renames local authorities" do
      LocalAuthority.create! id: "S12000033", name: "City of Aberdeen"

      load_from_fixture "single"

      expect(LocalAuthority.find("S12000033").name).to eq("Aberdeen City")
    end

    it "renames local authorities without changing identities of pre-existing postcodes" do
      LocalAuthority.create! id: "S12000033", name: "City of Aberdeen"
      postcode = create_postcode canonical: "AB1 0AA", local_authority_id: "S12000033"

      load_from_fixture "single"

      expect(Postcode.normalise_and_find("AB1 0AA").id).to eq(postcode.id)
    end

    it "successfully renames a local authority when an LCA is assigned to it" do
      LocalAuthority.create! id: "S12000033", name: "City of Aberdeen"
      Office.create! id: generate_salesforce_id, name: "Aberdeen CAB", office_type: "member", local_authority_id: "S12000033"

      load_from_fixture "single"

      expect(LocalAuthority.find("S12000033").name).to eq("Aberdeen City")
    end

    it "successfully handles removal of a local authority when an LCA is assigned to it" do
      LocalAuthority.create! id: "X00000000", name: "Testtown City Council"
      office_id = generate_salesforce_id
      Office.create! id: office_id, name: "Aberdeen CAB", office_type: "member", local_authority_id: "X00000000"

      load_from_fixture "single"

      expect(Office.find(office_id).local_authority_id).to be_nil
    end
  end

  def load_from_fixture(postcode_file)
    postcode_loader = PostcodeLoader.new File.open File.expand_path("fixtures/postcodes/#{postcode_file}.csv", File.dirname(__FILE__))
    postcode_loader.load!
  end

  def load_from_fixture_with_error(postcode_file)
    expect { load_from_fixture postcode_file }.to raise_error PostcodeLoader::PostcodeLoadError
  end

  def create_postcode(vals)
    unless vals.key? :local_authority_id
      vals[:local_authority_id] =
        LocalAuthority.create!(id: "A#{SecureRandom.hex(4)}", name: "Testtown").id
    end
    Postcode.create!({ location: "POINT(0.7 51.3)" }.update(vals))
  end
end
