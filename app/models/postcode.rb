# frozen_string_literal: true

class Postcode < ApplicationRecord
  belongs_to :local_authority

  def self.normalise_and_find(postcode)
    find_by normalised: postcode.gsub(" ", "").downcase
  end
end
