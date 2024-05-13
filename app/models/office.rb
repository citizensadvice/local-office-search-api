# frozen_string_literal: true

class Office < ApplicationRecord
  attribute :location, :st_point, srid: 4326, geographic: true

  belongs_to :parent, class_name: "Office", optional: true
  has_many :children, class_name: "Office", foreign_key: "parent_id", dependent: :nullify, inverse_of: :parent

  belongs_to :local_authority, optional: true

  has_many :opening_times, class_name: "OpeningTimes", dependent: :destroy

  def opening_hours
    build_opening_times("office")
  end

  def telephone_advice_hours
    build_opening_times("telephone")
  end

  private

  def build_opening_times(opening_times_for)
    office_opening_times = opening_times.where(opening_time_for: opening_times_for).to_a

    opening_hours = {}
    %w[monday tuesday wednesday thursday friday saturday sunday].each do |day_of_week|
      todays_opening_times = office_opening_times.select { |opening_time| opening_time.day_of_week == day_of_week }
      opening_hours[day_of_week.to_sym] = todays_opening_times.map(&:range)
      opening_hours[day_of_week.to_sym].sort_by!(&:beginning)
    end
    opening_hours
  end
end
