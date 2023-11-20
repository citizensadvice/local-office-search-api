# frozen_string_literal: true

require "csv"
require "csv_helpers"
require "loader_helpers"
require "lss_loader/office_builder"
require "lss_loader/opening_time_builder"
require "lss_loader/validators"

module LssLoader
  class LssLoader
    include CsvHelpers
    include LoaderHelpers
    include OfficeBuilder
    include OpeningTimeBuilder
    include Validators

    def initialize(members_csv:, advice_locations_csv:, opening_hours_csv:, volunteer_roles_csv:, accessibility_info_csv:)
      @members_csv = CSV.new members_csv, headers: true, return_headers: true
      @advice_locations_csv = CSV.new advice_locations_csv, headers: true, return_headers: true
      @opening_hours_csv = CSV.new opening_hours_csv, headers: true, return_headers: true
      @volunteer_roles_csv = CSV.new volunteer_roles_csv, headers: true, return_headers: true
      @accessibility_info_csv = CSV.new accessibility_info_csv, headers: true, return_headers: true
      initialise_csv_headers!
    end

    def load!
      ActiveRecord::Base.transaction do
        defer_integrity_checks_until_commit!
        validate_csv_headers!
        Office.delete_all
        OpeningTimes.delete_all
        offices = build_office_records
        opening_times = build_opening_times(offices)
        offices.values.map(&:save!)
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
    end

    def build_office_records
      offices = {}
      build_office_records_from_members_csv(offices)
      build_office_records_from_advice_locations_csv(offices)
      apply_accessibility_info_from_csv(offices)
      apply_volunteer_roles_from_csv(offices)

      nullify_dangling_parent_ids! offices
      nullify_dangling_local_authority_ids! offices
      offices
    end

    def build_opening_times(offices)
      @opening_hours_csv.map { |row| build_opening_time_from_row(row, offices) }.compact
    end

    def build_office_records_from_members_csv(offices)
      @members_csv.each do |row|
        office = office_from_member_row row
        offices[office[:id]] = office
      end
    end

    def build_office_records_from_advice_locations_csv(offices)
      @advice_locations_csv.each do |row|
        next if advice_location_row_is_excluded?(row)

        office = office_from_advice_location_row row
        offices[office[:id]] = office
      end
    end

    def apply_opening_hours_from_csv(offices)
      @opening_hours_csv.each do |row|
        apply_opening_hours! offices, row
      end
    end

    def apply_accessibility_info_from_csv(offices)
      @accessibility_info_csv.each do |row|
        apply_accessibility_info! offices, row
      end
    end

    def apply_volunteer_roles_from_csv(offices)
      @volunteer_roles_csv.each do |row|
        apply_volunteer_roles! offices, row
      end
    end

    def nullify_dangling_parent_ids!(offices)
      orphaned_offices = offices.values.select { |office| !office.parent_id.nil? && !offices.key?(office.parent_id) }
      orphaned_offices.each do |office|
        office.parent_id = nil
      end
    end

    def nullify_dangling_local_authority_ids!(offices)
      local_authority_ids = LocalAuthority.ids.to_set
      orphaned_offices = offices.values.reject { |office| local_authority_ids.include? office.local_authority_id }
      orphaned_offices.each do |office|
        office.local_authority_id = nil
      end
    end

    def defer_integrity_checks_until_commit!
      office_local_authority_foreign_key = "fk_rails_5a2ab5b59d"
      office_parent_foreign_key = "fk_rails_b381f08761"
      defer_constraint_until_commit! office_local_authority_foreign_key
      defer_constraint_until_commit! office_parent_foreign_key
    end
  end

  class LssLoadError < StandardError
  end
end
