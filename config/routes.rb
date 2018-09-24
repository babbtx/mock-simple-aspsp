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
  end
end
