Rails.application.routes.draw do
  defaults format: false do
    scope '/OpenBanking/v2' do
      resources :accounts, only: [:index, :show] do
        resources :transactions, only: [:index]
        resources :balances, only: [:index]
        resources :statements, only: [:index, :show] do
          resources :transactions, only: [:index], controller: :statement_transactions
          resource :file, only: [:show], controller: :statement_download
        end
      end
      resources :transactions, only: [:index]
      resources :balances, only: [:index]
      resources :statements, only: [:index]
    end

    namespace :private do
      resource :permissions, only: [:show]
      resources :accounts, only: [:index, :show]
      resources :balances, only: [:index]
      resources :transfers, only: [:create]
      resources :users, only: [] do
        resources :accounts, only: [:index]
        resources :balances, only: [:index]
      end
    end
  end
end
