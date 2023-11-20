# frozen_string_literal: true

class OpeningTimes < ApplicationRecord
  attribute :range, TimerangeType.new

  belongs_to :office
end
