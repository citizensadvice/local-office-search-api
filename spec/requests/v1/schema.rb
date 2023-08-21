# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength

module ApiV1Schema
  JSON_PROBLEM = {
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://www.rfc-editor.org/rfc/rfc7807",
    type: :object,
    properties: {
      type: { type: :string, format: :uri },
      title: { type: :string },
      status: { type: :number }
    },
    required: [:type],
    additionalProperties: false
  }.freeze

  NULLABLE_STRING = %i[string null].freeze

  GEO_JSON_POINT = {
    "$id": "https://geojson.org/schema/Point.json",
    type: :object,
    properties: {
      type: { type: :string, enum: ["Point"] },
      coordinates: { type: :array, items: { type: :number }, minItems: 2, maxItems: 2 }
    },
    required: %w[type coordinates],
    additionalProperties: false
  }.freeze

  TIME_OF_DAY = {
    type: :string,
    pattern: '^\d{2}:\d{2}:\d{2}$'
  }.freeze

  TIME_RANGE = {
    type: :object,
    properties: { opens: TIME_OF_DAY, closes: TIME_OF_DAY },
    required: %w[opens closes],
    additionalProperties: false
  }.freeze

  NULLABLE_TIME_RANGE = [:null, TIME_RANGE].freeze

  OPENING_HOURS = {
    type: :object,
    properties: {
      information: { type: NULLABLE_STRING },
      monday: { type: NULLABLE_TIME_RANGE },
      tuesday: { type: NULLABLE_TIME_RANGE },
      wednesday: { type: NULLABLE_TIME_RANGE },
      thursday: { type: NULLABLE_TIME_RANGE },
      friday: { type: NULLABLE_TIME_RANGE },
      saturday: { type: NULLABLE_TIME_RANGE },
      sunday: { type: NULLABLE_TIME_RANGE }
    },
    required: %w[information monday tuesday wednesday thursday friday saturday sunday],
    additionalProperties: false
  }.freeze

  OFFICE_TYPE = { type: :string, enum: %w[member office outreach] }.freeze

  RELATED_OBJECT = {
    type: :object,
    properties: {
      id: { type: :string },
      type: OFFICE_TYPE,
      name: { type: :string }
    },
    requires: %i[id type name],
    additionalProperties: false
  }.freeze

  OFFICE = {
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://local-office-search.citizensadvice.org.uk/schemas/v1/office",
    type: :object,
    properties: {
      id: { type: :string },
      type: OFFICE_TYPE,
      name: { type: :string },
      about_text: { type: NULLABLE_STRING },
      accessibility_information: { type: :array, items: { type: :string } },
      street: { type: NULLABLE_STRING },
      city: { type: NULLABLE_STRING },
      county: { type: NULLABLE_STRING },
      postcode: { type: NULLABLE_STRING },
      location: { type: [:null, GEO_JSON_POINT] },
      email: { type: NULLABLE_STRING },
      website: { type: NULLABLE_STRING },
      phone: { type: NULLABLE_STRING },
      allows_drop_ins: { type: :boolean },
      opening_hours: OPENING_HOURS,
      telephone_advice_hours: OPENING_HOURS,
      relations: { type: :array, items: RELATED_OBJECT }
    },
    required: %i[id name about_text accessibility_information street city postcode location email website phone
                 allows_drop_ins opening_hours telephone_advice_hours relations],
    additionalProperties: false
  }.freeze

  SEARCH_RESULT = {
    type: :object,
    properties: {
      id: { type: :string },
      name: { type: :string },
      contact_methods: { type: :array, items: { type: :string, enum: %w[phone email drop_in] } }
    },
    required: %i[id name contact_methods],
    additionalProperties: false
  }.freeze

  SEARCH_RESULTS = {
    "$schema": "https://json-schema.org/draft/2019-09/schema",
    "$id": "https://local-office-search.citizensadvice.org.uk/schemas/v1/results",
    type: :object,
    properties: {
      match_type: { type: :string, enum: %w[exact fuzzy unknown out_of_area_scotland out_of_area_ni],
                    description: %(
                                * `exact` means the search term matched an exact location, so only offices which serve the exact location
                                   are shown (this could include no locations).
                                * `fuzzy` means the search term matched a wider locality and not an individual point, so the results may
                                   include offices which can not serve that exact location.
                                * `unknown` means the search term was unable to be interpreted or matched to a location
                                  (so there are no results).
                                * `out_of_area_scotland` and `out_of_area_ni` means the search term matched exactly, but to a location in
                                  Scotland or Northern Ireland which is not in the network coverage area.
                                ) },
      results: { type: :array, items: SEARCH_RESULT }
    },
    required: %i[match_type results],
    additionalProperties: false
  }.freeze
end
# rubocop:enable Metrics/ModuleLength
