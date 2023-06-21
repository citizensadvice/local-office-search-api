# frozen_string_literal: true

module IdGenerator
  def generate_salesforce_id
    SecureRandom.hex(9)
  end
end
