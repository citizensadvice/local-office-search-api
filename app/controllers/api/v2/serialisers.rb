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
    end
  end
end
