# frozen_string_literal: true

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
end
