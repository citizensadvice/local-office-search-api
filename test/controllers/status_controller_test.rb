# frozen_string_literal: true

require "test_helper"

class StatusControllerTest < ActionDispatch::IntegrationTest
  test "should be OK when the database is fine" do
    get status_url
    assert_response :success
  end

  test "should be 503 when the database is unavailable" do
    ActiveRecord::Base.remove_connection
    get status_url
    assert_response :service_unavailable
    ActiveRecord::Base.establish_connection
  end
end
