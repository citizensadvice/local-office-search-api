# frozen_string_literal: true

module Api
  module V2
    module Serialisers
      def office_as_json(office)
        office.as_json(only: %i[id name about_text accessibility_information street city county postcode location email website phone
                                allows_drop_ins]).tap do |json|
          json[:type] = office.office_type
          json[:relations] = build_relations_json(office)
          json[:opening_hours] = opening_times_as_json(office.opening_hours_information, office.opening_hours)
          json[:telephone_advice_hours] = opening_times_as_json(office.telephone_advice_hours_information, office.telephone_advice_hours)
        end
      end

      def office_as_search_result_json(office)
        {
          id: office.id,
          name: office.name,
          street: office.street,
          city: office.city,
          county: office.county,
          postcode: office.postcode,
          contact_methods: contact_methods(office)
        }
      end

      def office_as_relation_json(office)
        {
          id: office.id,
          name: office.name,
          type: office.office_type
        }
      end

      def volunteering_opportunity_as_json(office)
        {
          id: office.id,
          office: office_as_json(office),
          roles: office.volunteer_roles,
          volunteer_recruitment_email: office.volunteer_recruitment_email
        }
      end

      def volunteering_opportunity_as_search_result_json(office, distance_from)
        {
          id: office.id,
          office: office_as_search_result_json(office),
          roles: office.volunteer_roles,
          distance: distance_in_miles(distance_from, office.location)
        }
      end

      private

      def build_relations_json(office)
        relations = []
        relations << office_as_relation_json(office.parent) unless office.parent.nil?
        office.children.each do |child|
          relations << office_as_relation_json(child)
        end
        relations
      end

      def opening_times_as_json(information, opening_hours)
        opening_times = { information: }
        opening_hours.each do |day, ranges|
          opening_times[day] = ranges.map do |range|
            { opens: range.beginning.strftime("%H:%M:%S"), closes: range.ending.strftime("%H:%M:%S") }
          end
        end
        opening_times
      end

      def contact_methods(office)
        methods = []
        methods << "drop_in" if office.allows_drop_ins
        methods << "phone" unless office.phone.nil?
        methods << "email" unless office.email.nil?
        methods
      end

      def distance_in_miles(location1, location2)
        if location1.nil? || location2.nil?
          nil
        else
          (location1.distance(location2) / 1609.34).round(2)
        end
      end
    end
  end
end
