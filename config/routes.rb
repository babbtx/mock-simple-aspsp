Rails.application.routes.draw do
  defaults format: 'json' do
    scope '/OpenBanking/v1' do
      resources :accounts, only: [:index, :show]
    end
  end
end
