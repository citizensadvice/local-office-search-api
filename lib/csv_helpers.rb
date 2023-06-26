# frozen_string_literal: true

module CsvHelpers
  def tod_from_val(val)
    match = /^(?<h>\d{2}):(?<m>\d{2}):(?<s>\d{2}).(?<ms>\d{3})Z$/.match(val)

    Tod::TimeOfDay.new match[:h].to_i, match[:m].to_i, match[:s].to_i + (match[:ms].to_i / 1000.0)
  end

  def str_or_nil(val)
    return nil if val == "null"

    val
  end

  def point_wkt_or_nil(latitude, longitude)
    return nil if latitude.nil? || longitude.nil?

    "POINT(#{longitude} #{latitude})"
  end

  def array_from_value(val)
    return [] if val == "null"

    val.split ";"
  end
end
