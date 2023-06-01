# frozen_string_literal: true

class Office < ApplicationRecord
  attribute :opening_hours_monday, :string, default: "empty"
  attribute :opening_hours_tuesday, :string, default: "empty"
  attribute :opening_hours_wednesday, :string, default: "empty"
  attribute :opening_hours_thursday, :string, default: "empty"
  attribute :opening_hours_friday, :string, default: "empty"
  attribute :opening_hours_saturday, :string, default: "empty"
  attribute :opening_hours_sunday, :string, default: "empty"
  attribute :telephone_advice_hours_monday, :string, default: "empty"
  attribute :telephone_advice_hours_tuesday, :string, default: "empty"
  attribute :telephone_advice_hours_wednesday, :string, default: "empty"
  attribute :telephone_advice_hours_thursday, :string, default: "empty"
  attribute :telephone_advice_hours_friday, :string, default: "empty"
  attribute :telephone_advice_hours_saturday, :string, default: "empty"
  attribute :telephone_advice_hours_sunday, :string, default: "empty"

  belongs_to :parent, class_name: "Office", optional: true
  has_many :children, class_name: "Office", foreign_key: "parent_id"
end
