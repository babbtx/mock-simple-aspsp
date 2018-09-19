Rails.application.routes.draw do
  defaults format: 'json' do
    scope '/OpenBanking/v2' do
      resources :accounts, only: [:index, :show]
      resources :transactions, only: [:index]
    end
  end
end
