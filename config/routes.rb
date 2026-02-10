Rails.application.routes.draw do
  namespace :admin do
    resources :features, only: [:index, :new, :create, :edit, :update]
  end
  
  root "admin/features#index"
end
