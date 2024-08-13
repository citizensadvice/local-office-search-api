# frozen_string_literal: true

class ServedArea < ApplicationRecord
  belongs_to :office
  belongs_to :local_authority
end
