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

      @account_csv.each do |row|
        office = office_from_row row
        office.save!
      end
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

  # rubocop:disable Metrics/AbcSize
  def office_from_row(row)
    Office.new id: row["Id"],
               name: row["Name"],
               office_type: record_type_id_to_office_type(row["RecordTypeId"]),
               legacy_id: str_or_nil(row["Serial_Number__c"]),
               about_text: str_or_nil(row["About_our_advice_service__c"]),
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

  def str_or_nil(val)
    case val
    when "null"
      nil
    else
      val
    end
  end

  def point_wkt_or_nil(latitude, longitude)
    return nil if latitude.nil? || longitude.nil?

    "POINT(#{longitude} #{latitude})"
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
