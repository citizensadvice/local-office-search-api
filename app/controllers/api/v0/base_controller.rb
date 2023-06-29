# frozen_string_literal: true

module Api
  module V0
    class BaseController < ::ApplicationController
      include ::ActionController::HttpAuthentication::Basic::ControllerMethods

      http_basic_authenticate_with name: ENV.fetch("LOCAL_OFFICE_SEARCH_EPISERVER_USER"),
                                   password: ENV.fetch("LOCAL_OFFICE_SEARCH_EPISERVER_PASSWORD")
    end
  end
end
