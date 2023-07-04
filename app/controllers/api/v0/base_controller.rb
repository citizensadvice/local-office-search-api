# frozen_string_literal: true

require "securerandom"

module Api
  module V0
    class BaseController < ::ApplicationController
      include ::ActionController::HttpAuthentication::Basic::ControllerMethods

      # this falls back to random strings if the env var is not set - so that we 'fail safe'
      # and never accidentally open to the world or fall back to some hard-coded creds
      http_basic_authenticate_with name: ENV.fetch("LOCAL_OFFICE_SEARCH_EPISERVER_USER", SecureRandom.base64(32)),
                                   password: ENV.fetch("LOCAL_OFFICE_SEARCH_EPISERVER_PASSWORD", SecureRandom.base64(32))
    end
  end
end
