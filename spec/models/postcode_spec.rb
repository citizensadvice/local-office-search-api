# frozen_string_literal: true

require "rails_helper"

RSpec.describe Postcode do
  it "allows looking up a postcode in normalised form" do
    postcode = create_postcode canonical: "A1 2BC"

    expect(described_class.find_by(normalised: "a12bc").id).to eq(postcode.id)
  end

  it "does not allow two postcodes with the same normalised form to exist" do
    create_postcode canonical: "A1 2BC"

    expect { create_postcode canonical: "A12BC" }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "has a helper which normalises and looks up in normalised form" do
    postcode = create_postcode canonical: "A1 2BC"

    expect(described_class.normalise_and_find("A12BC").id).to eq(postcode.id)
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
