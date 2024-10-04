# frozen_string_literal: true

require "csv"
require "csv_helpers"
require "loader_helpers"
require "lss_loader/office_builder"
require "lss_loader/opening_time_builder"
require "lss_loader/validators"

module LssLoader
  class LssLoader
    include LoaderHelpers
    include Validators

    # rubocop:disable Metrics/ParameterLists
    def initialize(members_csv:,
                   advice_locations_csv:,
                   opening_hours_csv:,
                   volunteer_roles_csv:,
                   accessibility_info_csv:,
                   local_authorities_csv:)
      @members_csv = CSV.new(members_csv, headers: true, return_headers: true)
      @advice_locations_csv = CSV.new(advice_locations_csv, headers: true, return_headers: true)
      @opening_hours_csv = CSV.new(opening_hours_csv, headers: true, return_headers: true)
      @volunteer_roles_csv = CSV.new(volunteer_roles_csv, headers: true, return_headers: true)
      @accessibility_info_csv = CSV.new(accessibility_info_csv, headers: true, return_headers: true)
      @local_authorities_csv = CSV.new(local_authorities_csv, headers: true, return_headers: true)
      initialise_csv_headers!
    end
    # rubocop:enable Metrics/ParameterLists

    def load!
      ActiveRecord::Base.transaction do
        defer_integrity_checks_until_commit!
        validate_csv_headers!
        clear_existing_records!

        offices, served_areas = OfficeBuilder.new(members_csv: @members_csv,
                                                  advice_locations_csv: @advice_locations_csv,
                                                  accessibility_info_csv: @accessibility_info_csv,
                                                  volunteer_roles_csv: @volunteer_roles_csv,
                                                  local_authorities_csv: @local_authorities_csv).build
        opening_times = OpeningTimeBuilder.new(@opening_hours_csv, offices.map(&:id)).build

        offices.map(&:save!)
        served_areas.map(&:save!)
        opening_times.map(&:save!)
      end
    end

    private

    def initialise_csv_headers!
      @members_csv.shift if @members_csv.headers == true
      @advice_locations_csv.shift if @advice_locations_csv.headers == true
      @opening_hours_csv.shift if @opening_hours_csv.headers == true
      @volunteer_roles_csv.shift if @volunteer_roles_csv.headers == true
      @accessibility_info_csv.shift if @accessibility_info_csv.headers == true
      @local_authorities_csv.shift if @local_authorities_csv.headers == true
    end

    def clear_existing_records!
      ServedArea.delete_all
      OpeningTimes.delete_all
      Office.delete_all
    end

    def defer_integrity_checks_until_commit!
      office_parent_foreign_key = "fk_rails_b381f08761"
      defer_constraint_until_commit! office_parent_foreign_key
    end
  end

  class LssLoadError < StandardError
  end
end
