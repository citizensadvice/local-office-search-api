# frozen_string_literal: true

class TimerangeType < ActiveRecord::Type::Value
  def serialize(value)
    return "empty" if value.nil?

    "['#{value.beginning}','#{value.ending}'#{value.exclude_end? ? ')' : ']'}"
  end

  def deserialize(value)
    return nil if value == "empty"
    raise RangeError, "unable to handle exclusive opening types" if value[0] == "("

    exclude_end = value[-1] == ")"
    beginning, ending = value[1...-1].split(",")
    Tod::Shift.new Tod::TimeOfDay.parse(beginning), Tod::TimeOfDay.parse(ending), exclude_end
  end
end
