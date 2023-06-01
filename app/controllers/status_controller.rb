# frozen_string_literal: true

class StatusController < ApplicationController
  def index
    # head ActiveRecord::Base.connected? ? :ok : :service_unavailable
    head :ok
  end
end
