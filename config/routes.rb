Rails.application.routes.draw do
  root "posts#index"

  resources :posts do
    member do
      post :improve
    end
  end

end
