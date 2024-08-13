# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  has_many :postcodes, dependent: nil
  has_many :offices, dependent: nil
  has_many :served_areas, dependent: :destroy
end
