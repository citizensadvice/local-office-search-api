# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Service Status API" do
  path "/status" do
    get "Checks system status" do
      response "200", "Service is available" do
        run_test!
      end

      response "503", "Service is unavailable"
    end
  end
end
