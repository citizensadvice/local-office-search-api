class ApplicationController < ActionController::Base

  # Temporary action to check the app can connect to the database in AWS. This can
  # be deleted once we've added some real routes.
  def check_database
    db_version = ActiveRecord::Base.connection.select_value("SELECT VERSION()")

    render plain: db_version
  end
end
