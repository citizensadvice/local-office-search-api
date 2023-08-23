# frozen_string_literal: true

module CsvHelpers
  def tod_from_val(val)
    match = /^(?<h>\d{2}):(?<m>\d{2})$/.match(val)

    Tod::TimeOfDay.new match[:h].to_i, match[:m].to_i
  end

  def str_or_nil(val)
    return nil if ["null", ""].include?(val)

    val
  end

  def bool_from_val(val)
    val == "TRUE"
  end

  def point_wkt_or_nil(latitude, longitude)
    return nil if latitude.nil? || longitude.nil?

    "POINT(#{longitude} #{latitude})"
  end

  def array_from_value(val)
    val = str_or_nil(val)
    return [] if val.nil?

    val.split ";"
  end
end
