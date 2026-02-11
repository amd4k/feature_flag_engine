Rails.application.routes.draw do
  namespace :admin do
    resources :features, only: [:index, :new, :create, :edit, :update] do
      resources :feature_overrides, only: [:create, :destroy]
    end
  end
  
  root "admin/features#index"
end
