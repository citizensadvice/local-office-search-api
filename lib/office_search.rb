# frozen_string_literal: true

module OfficeSearch
  def self.search_by_location(near, opts)
    opts[:only_with_vacancies] ||= false
    opts[:only_in_same_local_authority] ||= false

    location, local_authority_id = find_location(near)

    [build_query(location, local_authority_id, opts), location]
  end

  class SearchUnknownLocationError < StandardError
  end

  class SearchOutOfAreaError < StandardError
    attr_reader :country

    def initialize(msg, country)
      @country = country
      super(msg)
    end
  end

  def self.find_location(near)
    postcode = Postcode.normalise_and_find(near)
    raise SearchUnknownLocationError if postcode.nil?

    [postcode.location, postcode.local_authority_id]
  end

  def self.build_query(location, local_authority_id, opts)
    q = Office.all
    q = if opts[:only_in_same_local_authority]
          q.where(local_authority_id:)
        else
          q.limit(10)
        end

    q.order(Office.arel_table[:location].st_distance(location))
    q = q.where.not(volunteer_roles: []) if opts[:only_with_vacancies]
    q
  end
end
