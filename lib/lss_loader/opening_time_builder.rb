# frozen_string_literal: true

module LssLoader
  module OpeningTimeBuilder
    private

    def build_opening_time_from_row(row, offices)
      return unless str_or_nil(row["session_type"]).present? && offices.key?(row["advice_location_salesforce_id"])

      range = shift_from_row(row)

      return if range.nil?

      OpeningTimes.new(office_id: row["advice_location_salesforce_id"],
                       opening_time_for: opening_time_type_from_row(row),
                       day_of_week: row["session_day"].downcase,
                       range:)
    end

    def opening_time_type_from_row(row)
      case row["session_type"]
      when "Local office opening hours"
        "office"
      when "Telephone advice hours"
        "telephone"
      else
        raise LssLoadError, "Unrecognised opening hour type #{row['session_type']}"
      end
    end

    def shift_from_row(row)
      start_time = str_or_nil(row["start_time_value"])
      end_time = str_or_nil(row["end_time_value"])
      return nil if start_time.nil? || end_time.nil?

      beginning = tod_from_val(start_time)
      ending = tod_from_val(end_time)
      Tod::Shift.new(beginning, ending) unless beginning > ending
    end
  end
end
