# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "/status", to: "status#index"

  namespace :api do
    namespace :v1 do
      get "/offices/:id", to: "office#show"
    end
  end
end
