# frozen_string_literal: true

class Office < ApplicationRecord
  attribute :opening_hours_monday, TimerangeType.new
  attribute :opening_hours_tuesday, TimerangeType.new
  attribute :opening_hours_wednesday, TimerangeType.new
  attribute :opening_hours_thursday, TimerangeType.new
  attribute :opening_hours_friday, TimerangeType.new
  attribute :opening_hours_saturday, TimerangeType.new
  attribute :opening_hours_sunday, TimerangeType.new
  attribute :telephone_advice_hours_monday, TimerangeType.new
  attribute :telephone_advice_hours_tuesday, TimerangeType.new
  attribute :telephone_advice_hours_wednesday, TimerangeType.new
  attribute :telephone_advice_hours_thursday, TimerangeType.new
  attribute :telephone_advice_hours_friday, TimerangeType.new
  attribute :telephone_advice_hours_saturday, TimerangeType.new
  attribute :telephone_advice_hours_sunday, TimerangeType.new

  belongs_to :parent, class_name: "Office", optional: true
  has_many :children, class_name: "Office", foreign_key: "parent_id", dependent: :nullify, inverse_of: :parent
end
