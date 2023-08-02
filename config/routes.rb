# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "/status", to: "status#index"

  namespace :api do
    namespace :v0 do
      get "/json/location/id/:id", to: "location#get"
      get "/json/location/list", to: "location#list"
      get "/json/member/id/*id", to: "member#get"
      get "/json/member/list", to: "member#list"
      get "/json/vacancy/id/:id", to: "vacancy#get"
      get "/json/vacancy/list", to: "vacancy#list"
    end

    namespace :v1 do
      get "/offices/", to: "office#search"
      get "/offices/:id", to: "office#show", as: :office
    end
  end
end
