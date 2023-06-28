# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "/status", to: "status#index"

  namespace :api do
    namespace :v0 do
      get "/location/id/:id", to: "location#get"
      get "/location/list", to: "location#list"
      get "/member/id/*id", to: "member#get"
      get "/member/list", to: "member#list"
      get "/vacancy/id/:id", to: "vacancy#get"
      get "/vacancy/list", to: "vacancy#list"
    end

    namespace :v1 do
      get "/offices/:id", to: "office#show", as: :office
    end
  end
end
