Rails.application.routes.draw do
  defaults format: 'json' do
    scope '/OpenBanking/v2' do
      resources :accounts, only: [:index, :show] do
        resources :transactions
      end
      resources :transactions, only: [:index]
    end
  end
end
