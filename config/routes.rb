# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "/status", to: "status#index"

  # Temporary route to check the app can connect to the database in AWS. This can
  # be deleted once we've added some real routes.
  get "/check-database", to: "application#check_database"
end
