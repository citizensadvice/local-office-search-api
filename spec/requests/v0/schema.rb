# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module BureauDetailsSchema
  NULLABLE_STRING = %i[string null].freeze

  ADDRESS_SCHEMA = {
    type: :object,
    properties: {
      address: { type: :string },
      town: { type: :string },
      county: { type: NULLABLE_STRING },
      postcode: { type: NULLABLE_STRING },
      latLong: { type: :array, items: { type: :number }, minItems: 2, maxItems: 2 }
    },
    required: %w[address town county postcode latLong],
    additionalProperties: false
  }.freeze

  ADDRESS_WITH_LOCAL_AUTHORITY_SCHEMA = {
    type: :object,
    properties: {
      onsDistrictCode: { type: :string },
      localAuthority: { type: :string }
    }.merge(ADDRESS_SCHEMA[:properties]),
    required: %w[address town county postcode latLong onsDistrictCode localAuthority],
    additionalProperties: false
  }.freeze

  OPENING_TIME_SCHEMA = {
    type: :object,
    properties: {
      day: { type: :string, enum: %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday] },
      start1: { type: NULLABLE_STRING },
      end1: { type: NULLABLE_STRING },
      start2: { type: NULLABLE_STRING },
      end2: { type: NULLABLE_STRING },
      notes: { type: NULLABLE_STRING }
    },
    required: %w[day start1 end1 start2 end2 notes],
    additionalProperties: false
  }.freeze

  CONTACT_SCHEMA = {
    type: :array,
    items: {
      type: :object,
      properties: {
        contact: { type: :string },
        description: { type: NULLABLE_STRING }
      },
      required: %w[contact description],
      additionalProperties: false
    }
  }.freeze

  OFFICE_SCHEMA = {
    type: :object,
    properties: {
      address: ADDRESS_WITH_LOCAL_AUTHORITY_SCHEMA,
      membershipNumber: { type: :string },
      name: { type: :string },
      serialNumber: { type: :string },
      inVCC: { type: :boolean },
      isBureau: { type: :boolean },
      isOutlet: { type: :boolean },
      features: { type: :array, items: { type: :string } },
      notes: { type: NULLABLE_STRING },
      openingTimes: { type: :array, items: OPENING_TIME_SCHEMA },
      publicContacts: {
        type: :object,
        properties: {
          email: CONTACT_SCHEMA,
          fax: CONTACT_SCHEMA,
          minicom: CONTACT_SCHEMA,
          telephone: CONTACT_SCHEMA,
          website: CONTACT_SCHEMA
        },
        required: %w[email fax minicom telephone website],
        additionalProperties: false
      },
      telephoneTimes: { type: :array, items: OPENING_TIME_SCHEMA }
    },
    required: %w[address membershipNumber name serialNumber inVCC isBureau isOutlet features notes openingTimes publicContacts
                 telephoneTimes],
    additionalProperties: false
  }.freeze

  VACANCY_SCHEMA = {
    type: :object,
    properties: {
      address: ADDRESS_SCHEMA,
      membershipNumber: { type: :string },
      name: { type: :string },
      serialNumber: { type: :string },
      email: { type: :string },
      id: { type: :string },
      roles: { type: :array, items: { type: :string } },
      telephone: { type: NULLABLE_STRING },
      website: { type: NULLABLE_STRING }
    },
    required: %w[address membershipNumber name serialNumber email id roles telephone website],
    additionalProperties: false
  }.freeze

  VACANCY_LIST_SCHEMA = {
    type: :object,
    properties: { distance: { type: :number } }.merge(VACANCY_SCHEMA[:properties]),
    required: VACANCY_SCHEMA[:required] + %w[distance],
    additionalProperties: false
  }.freeze

  MEMBER_SCHEMA = {
    type: :object,
    properties: {
      address: ADDRESS_WITH_LOCAL_AUTHORITY_SCHEMA,
      membershipNumber: { type: :string },
      name: { type: :string },
      serialNumber: { type: :string },
      charityNumber: { type: :string },
      companyNumber: { type: :string },
      notes: { type: NULLABLE_STRING },
      services: {
        type: :object,
        properties: {
          bureaux: { type: :array, items: OFFICE_SCHEMA },
          outlets: { type: :array, items: OFFICE_SCHEMA }
        },
        required: %w[bureaux outlets],
        additionalProperties: false
      },
      staff: { type: :null },
      vacancies: { type: :array, items: VACANCY_SCHEMA },
      website: { type: NULLABLE_STRING }
    },
    required: %w[address membershipNumber name serialNumber charityNumber notes services staff vacancies website],
    additionalProperties: false
  }.freeze
end
# rubocop:enable Metrics/ModuleLength
