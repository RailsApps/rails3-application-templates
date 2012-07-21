Rails3Subdomains::Application.routes.draw do
  authenticated :user do
    root :to => 'home#index'
  end
  devise_for :users
  resources :users, :only => [:show, :index]
  constraints(Subdomain) do
    match '/' => 'profiles#show'
  end
  root :to => "home#index"
end
