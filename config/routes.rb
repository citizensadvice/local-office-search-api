Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  # Temporary route to check the app can connect to the database in AWS. This can
  # be deleted once we've added some real routes.
  get "/check-database", to: "application#check_database"
end
