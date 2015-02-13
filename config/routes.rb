require 'resque/server'
Rails.application.routes.draw do

  devise_for :users
  resources :people
  resources :static_pages
  resources :scrapes
  resources :twitter_blasts
  resources :rss_feed_collections
  resources :user_tinder_bots
  resources :craig_crams
  resources :emails
  resources :people_scrapes
  resources :augur_data

  get '/scrape_ape' => "scrapes#index"
  get '/tinder_bot' => "user_tinder_bots#index"
  get '/user_tinder_bots/run' => "user_tinder_bots#run"

  get '/twitter_blaster' => "twitter_blasts#index"
  get '/craig_crammer' => "craig_crams#index"
  get '/sms_blaster' => "static_pages#sms_blaster"
  get '/rss_retweeter' => "rss_feed_collections#index"
  put '/rss/save' => "static_pages#save_rss_feeds"
  put '/scrape/:id/run' => "scrapes#run"
  put '/scrape/:id/restart' => "scrapes#restart"
  post '/text' => "sms_blasts#text"

  get '/persons/' => 'people#emails'
  post '/persons' => 'people#lookup'
  get '/people_scrape' => 'people_scrapes#index'

  post '/webhook/clearbit' => 'webhook#clearbit'

  get '/tutor/get' => 'persons#tutor_lookup'
  post '/tutor/new' => 'persons#tutor_create'

  post '/send_email' => 'application#send_email'

  post '/craigslist/scrape' => 'scrapes#craigslist_scrape'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  root :to => 'static_pages#index'
  mount Resque::Server, :at => "/resque"
  get '/scrape/stop_all', to: "scrapes#stop_all_scrapes"
  get '/scrape/get_scrapes', to: "scrapes#get_scrapes_table_info"
  get '/twitter_blast/get_blasts', to: "twitter_blasts#get_blasts"
  get '/twitter_blast/get_handle_list', to: "twitter_blasts#get_handle_list"
  get '/twitter_blast/:id/run', to: "twitter_blasts#run"
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'
end
