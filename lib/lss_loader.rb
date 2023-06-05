# frozen_string_literal: true

module LssLoader
  # @param [CSV::Table] account_csv
  # @param [CSV::Table] opening_hours_csv
  def self.update_offices(account_csv, opening_hours_csv)
    ActiveRecord::Base.transaction do
      raise LssLoadError, "Accounts CSV file was not in expected format" unless account_csv.headers == %w[
        Id Name ParentId Serial_Number__c RecordTypeId About_our_advice_service__c Access_details__c
        BillingStreet BillingCity BillingPostalCode BillingLatitude BillingLongitude Email__c Website Phone
        Closing_Date__c Reopening_Date__c Closed__c
        Recruiting_volunteers__c Select_the_roles_you_re_recruiting_for__c Volunteer_Recruitment_Email__c
        Membership_Number__c Local_Office_Opening_Hours_Information__c Telephone_Advice_Hours_Information__c
      ]
      raise LssLoadError, "Opening Hours CSV file was not in expected format" unless opening_hours_csv.headers == %w[
        Id Parent_Account__c RecordTypeId Weekday__c Start_Time__c End_Time__c Type__c
      ]

      ActiveRecord::Base.connection.truncate(Office.table_name)
    end
  end

  class LssLoadError < StandardError
  end
end
