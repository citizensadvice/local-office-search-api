# frozen_string_literal: true

class LssLoader
  # @param [CSV::Table] account_csv
  # @param [CSV::Table] opening_hours_csv
  def initialize(account_csv, opening_hours_csv)
    @account_csv = account_csv
    @opening_hours_csv = opening_hours_csv
  end

  def load!
    ActiveRecord::Base.transaction do
      validate_csv_headers!
      ActiveRecord::Base.connection.truncate(Office.table_name)
      offices = build_office_records
      offices.each_value(&:save!)
    end
  end

  private

  def validate_csv_headers!
    raise LssLoadError, "Accounts CSV file was not in expected format" unless @account_csv.headers == %w[
      Id Name ParentId Serial_Number__c RecordTypeId About_our_advice_service__c Access_details__c
      BillingStreet BillingCity BillingPostalCode BillingLatitude BillingLongitude Email__c Website Phone
      Closing_Date__c Reopening_Date__c Closed__c
      Recruiting_volunteers__c Select_the_roles_you_re_recruiting_for__c Volunteer_Recruitment_Email__c
      Membership_Number__c Local_Office_Opening_Hours_Information__c Telephone_Advice_Hours_Information__c
    ]
    raise LssLoadError, "Opening Hours CSV file was not in expected format" unless @opening_hours_csv.headers == %w[
      Id Parent_Account__c RecordTypeId Weekday__c Start_Time__c End_Time__c Type__c
    ]
  end

  def build_office_records
    offices = {}

    @account_csv.each do |row|
      office = office_from_row row
      offices[office[:id]] = office
    end

    @opening_hours_csv.each do |row|
      apply_opening_hours offices, row
    end

    offices
  end

  # rubocop:disable Metrics/AbcSize
  def office_from_row(row)
    Office.new id: row["Id"],
               name: row["Name"],
               office_type: record_type_id_to_office_type(row["RecordTypeId"]),
               legacy_id: str_or_nil(row["Serial_Number__c"]),
               about_text: str_or_nil(row["About_our_advice_service__c"]),
               accessibility_information: array_from_value(row["Access_details__c"]),
               street: str_or_nil(row["BillingStreet"]),
               city: str_or_nil(row["BillingCity"]),
               postcode: str_or_nil(row["BillingPostalCode"]),
               location: point_wkt_or_nil(row["BillingLatitude"], row["BillingLongitude"]),
               email: str_or_nil(row["Email__c"]),
               website: str_or_nil(row["Website"]),
               phone: str_or_nil(row["Phone"]),
               opening_hours_information: str_or_nil(row["Local_Office_Opening_Hours_Information__c"]),
               telephone_advice_hours_information: str_or_nil(row["Telephone_Advice_Hours_Information__c"])
  end
  # rubocop:enable Metrics/AbcSize

  def apply_opening_hours(offices, row)
    return unless row["Type__c"] != "null" && offices.key?(row["Parent_Account__c"])

    offices[row["Parent_Account__c"]].write_attribute column_from_row(row), shift_from_row(row)
  end

  def column_from_row(row)
    case row["Type__c"]
    when "Local office opening hours"
      "opening_hours_#{row['Weekday__c'].downcase}".to_sym
    when "Telephone advice hours"
      "telephone_advice_hours_#{row['Weekday__c'].downcase}".to_sym
    else
      raise LssLoadError, "Unrecognised opening hour type #{row['Type__c']}"
    end
  end

  def shift_from_row(row)
    return nil if row["Start_Time__c"] == "null" || row["End_Time__c"] == "null"

    beginning = tod_from_val(row["Start_Time__c"])
    ending = tod_from_val(row["End_Time__c"])
    Tod::Shift.new(beginning, ending) unless beginning > ending
  end

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

  def record_type_id_to_office_type(record_type_id)
    case record_type_id
    when "0124K000000HyUGQA0"
      :member
    when "0124K0000000qqTQAQ"
      :office
    when "0124K0000000qqUQAQ"
      :outreach
    else
      raise LssLoadError, "Unrecognised RecordTypeId #{record_type_id}"
    end
  end

  class LssLoadError < StandardError
  end
end
