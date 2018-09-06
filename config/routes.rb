Rails.application.routes.draw do
  devise_for :users
  scope "/admin" do
    resources :users
  end
  resources :games
  get 'home/index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root :to => 'games#index'
  post 'games/add_bgg'
end
