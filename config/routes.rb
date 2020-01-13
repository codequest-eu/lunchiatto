# frozen_string_literal: true
Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
  }
  root 'pages#index'

  namespace :api do
    resources :users, except: [:delete, :edit]
    resources :companies, only: [:show, :update]
    resources :invitations, only: [:create, :destroy]

    resources :transfers, only: [:index, :create] do
      member do
        put :accept
        put :reject
      end
    end

    resources :balances, only: [:index]

    resources :payments, only: [:create]

    resources :orders, except: [:new, :edit] do
      resources :dishes, except: [:new, :edit] do
        post :copy, on: :member
      end
      member do
        put :change_status
      end
      collection do
        get :latest
      end
    end
  end

  resources :companies, only: [:new, :create]
  resources :invitations, only: [:show, :create]
  resources :user_accesses, only: [:create]

  ### Single Page App ###
  %w(
    orders
    orders/today
    orders/today/:order_id
    orders/new orders/:order_id/edit
    orders/:order_id/dishes/:dish_id/edit
    orders/:order_id/dishes/new
    account_numbers
    settings
    transfers
    transfers/new
    edit_company
    members
    you
  ).each do |route|
    get route, to: 'dashboard#index'
  end
  get 'orders/:order_id', to: 'dashboard#index', as: 'order'

  # redirect from the dashboard for existing users
  get 'dashboard', to: redirect('orders/today')
  get 'balances', to: redirect('you')

  # redirect old /app urls to root
  get 'app/*a', to: redirect { |_path, req| req.original_url.gsub('app/', '') }
end
