# frozen_string_literal: true

module OfficeSearch
  def self.by_location(near, opts)
    opts[:only_with_vacancies] ||= false
    opts[:only_in_same_local_authority] ||= false

    location, local_authority_id = find_location(near)

    [build_query(location, local_authority_id, opts), location]
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

  def self.find_location(near)
    postcode = Postcode.normalise_and_find(near)
    raise UnknownLocationError if postcode.nil?
    raise OutOfAreaError, :ni if postcode.northern_irish?
    raise OutOfAreaError, :scotland if postcode.scottish?

    [postcode.location, postcode.local_authority_id]
  end

  def self.build_query(location, local_authority_id, opts)
    q = Office.all
    q = if opts[:only_in_same_local_authority]
          q.where(local_authority_id:)
        else
          q.limit(10)
        end

    q = q.where.not(volunteer_roles: []) if opts[:only_with_vacancies]
    q.order(Office.arel_table[:location].st_distance(location))
  end
end
