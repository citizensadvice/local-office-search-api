# frozen_string_literal: true

class LocalAuthority < ApplicationRecord
  has_many :postcodes, dependent: nil
end
