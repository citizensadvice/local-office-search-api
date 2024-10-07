# frozen_string_literal: true

module OfficeSearch
  def self.by_location(near, opts = {})
    opts[:only_with_vacancies] ||= false
    opts[:only_in_same_local_authority] ||= false

    exact_location_results = find_exact_location(near)
    if exact_location_results.nil?
      [by_fuzzy_location(near, opts), nil]
    else
      location, local_authority_id = exact_location_results
      [build_query_from_location(location, local_authority_id, opts), location]
    end
  end

  class UnknownLocationError < StandardError
  end

  class OutOfAreaError < StandardError
    attr_reader :country

    def initialize(country)
      super
      @country = country
    end

    def country_name
      case @country
      when :ni
        "Northern Ireland"
      when :scotland
        "Scotland"
      else
        @country.to_s
      end
    end
  end

  def self.find_exact_location(near)
    postcode = Postcode.normalise_and_find(near)
    return nil if postcode.nil?
    raise OutOfAreaError, :ni if postcode.northern_irish?
    raise OutOfAreaError, :scotland if postcode.scottish?

    [postcode.location, postcode.local_authority_id]
  end

  def self.build_query_from_location(location, local_authority_id, opts)
    q = Office.where(office_type: :office)
    q = if opts[:only_in_same_local_authority]
          q.joins(:served_areas).where(served_areas: { local_authority_id: })
        else
          q.limit(10)
        end

    q = q.where.not(volunteer_roles: []) if opts[:only_with_vacancies]
    q.order(Office.arel_table[:location].st_distance(location))
  end

  def self.by_fuzzy_location(near, opts)
    fuzzy_query = build_fuzzy_query(near, opts)
    raise UnknownLocationError if fuzzy_query.empty?

    fuzzy_query
  end

  def self.build_fuzzy_query(near, opts)
    office_with_local_authorities = Office.left_outer_joins(served_areas: :local_authority).distinct
    q = office_with_local_authorities.where(Office.arel_table[:name].matches("%#{near}%"))
    q = q.or(office_with_local_authorities.where(LocalAuthority.arel_table[:name].matches("%#{near}%")))
    q = q.where(office_type: :office)
    q = q.where.not(volunteer_roles: []) if opts[:only_with_vacancies]
    q.limit(10)
  end
end
