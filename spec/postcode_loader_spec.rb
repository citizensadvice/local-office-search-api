# frozen_string_literal: true

require "rails_helper"
require "postcode_loader"
require "csv"

RSpec.describe PostcodeLoader do
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

      expect(LocalAuthority.find("S12000033")).to eq("Aberdeen City")
    end

    it "renames local authorities without changing identities of pre-existing postcodes" do
      LocalAuthority.create! id: "S12000033", name: "City of Aberdeen"
      postcode = create_postcode canonical: "AB1 0AA", local_authority_id: "S12000033"

      load_from_fixture "single"

      expect(Postcode.normalise_and_find("AB1 0AA").id).to eq(postcode.id)
    end
  end

  def load_from_fixture(postcode_file)
    postcode_loader = PostcodeLoader.new File.expand_path("fixtures/postcodes/#{postcode_file}.csv", File.dirname(__FILE__))
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
    Postcode.create!({
      location: "POINT(0.7 51.3)"
    }.update(vals))
  end
end
