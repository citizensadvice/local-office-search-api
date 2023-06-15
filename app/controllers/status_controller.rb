# frozen_string_literal: true

class StatusController < ApplicationController
  def index
    ActiveRecord::Base.connection.execute("SELECT 1")
  rescue ActiveRecord::ConnectionNotEstablished
    head :service_unavailable
  else
    head :ok
  end
end
