# frozen_string_literal: true

module Api
  module V1
    module Serialisers
      # rubocop:disable Metrics/AbcSize
      def office_as_json(office)
        office.as_json(only: %i[id name about_text accessibility_information street city county postcode location email website phone
                                allows_drop_ins]).tap do |json|
          json[:type] = office.office_type
          json[:relations] = build_relations_json(office)
          json[:opening_hours] = {
            information: office.opening_hours_information,
            monday: opening_hours_as_json(office.opening_hours_monday),
            tuesday: opening_hours_as_json(office.opening_hours_tuesday),
            wednesday: opening_hours_as_json(office.opening_hours_wednesday),
            thursday: opening_hours_as_json(office.opening_hours_thursday),
            friday: opening_hours_as_json(office.opening_hours_friday),
            saturday: opening_hours_as_json(office.opening_hours_saturday),
            sunday: opening_hours_as_json(office.opening_hours_sunday)
          }
          json[:telephone_advice_hours] = {
            information: office.telephone_advice_hours_information,
            monday: opening_hours_as_json(office.telephone_advice_hours_monday),
            tuesday: opening_hours_as_json(office.telephone_advice_hours_tuesday),
            wednesday: opening_hours_as_json(office.telephone_advice_hours_wednesday),
            thursday: opening_hours_as_json(office.telephone_advice_hours_thursday),
            friday: opening_hours_as_json(office.telephone_advice_hours_friday),
            saturday: opening_hours_as_json(office.telephone_advice_hours_saturday),
            sunday: opening_hours_as_json(office.telephone_advice_hours_sunday)
          }
        end
      end
      # rubocop:enable Metrics/AbcSize

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

      def opening_hours_as_json(opening_hours)
        return nil if opening_hours.nil?

        { opens: opening_hours.beginning.strftime("%H:%M:%S"), closes: opening_hours.ending.strftime("%H:%M:%S") }
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
