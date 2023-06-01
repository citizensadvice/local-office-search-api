# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatusController, skip: "disabled until database connection is on live so we can get it initially deployed" do
  it "is OK when the database is fine" do
    get :index
    expect(response).to have_http_status :ok
  end

  it "is 503 when the database is unavailable" do
    ActiveRecord::Base.remove_connection
    get :index
    expect(response).to have_http_status :service_unavailable
    ActiveRecord::Base.establish_connection
  end
end
