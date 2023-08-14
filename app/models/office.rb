# frozen_string_literal: true

class Office < ApplicationRecord
  attribute :location, :st_point, srid: 4326, geographic: true
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

  belongs_to :local_authority, optional: true

  # rubocop:disable Metrics/AbcSize
  def as_json(options = nil)
    options ||= {}
    options[:only] =
      %i[id name about_text accessibility_information street city county postcode location email website phone allows_drop_ins]
    super(options).tap do |json|
      json[:type] = office_type
      json[:relations] = build_relations_json
      json[:opening_hours] = {
        information: opening_hours_information,
        monday: opening_hours_as_json(opening_hours_monday),
        tuesday: opening_hours_as_json(opening_hours_tuesday),
        wednesday: opening_hours_as_json(opening_hours_wednesday),
        thursday: opening_hours_as_json(opening_hours_thursday),
        friday: opening_hours_as_json(opening_hours_friday),
        saturday: opening_hours_as_json(opening_hours_saturday),
        sunday: opening_hours_as_json(opening_hours_sunday)
      }
      json[:telephone_advice_hours] = {
        information: telephone_advice_hours_information,
        monday: opening_hours_as_json(telephone_advice_hours_monday),
        tuesday: opening_hours_as_json(telephone_advice_hours_tuesday),
        wednesday: opening_hours_as_json(telephone_advice_hours_wednesday),
        thursday: opening_hours_as_json(telephone_advice_hours_thursday),
        friday: opening_hours_as_json(telephone_advice_hours_friday),
        saturday: opening_hours_as_json(telephone_advice_hours_saturday),
        sunday: opening_hours_as_json(telephone_advice_hours_sunday)
      }
    end
  end
  # rubocop:enable Metrics/AbcSize

  def as_relation_json
    {
      id:,
      name:,
      type: office_type
    }
  end

  private

  def build_relations_json
    relations = []
    relations << parent.as_relation_json unless parent.nil?
    children.each do |child|
      relations << child.as_relation_json
    end
    relations
  end

  def opening_hours_as_json(opening_hours)
    return nil if opening_hours.nil?

    { opens: opening_hours.beginning.strftime("%H:%M:%S"), closes: opening_hours.ending.strftime("%H:%M:%S") }
  end
end
