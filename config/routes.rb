Rails.application.routes.draw do
  get 'live' => 'live#live'

  get 'api/school'

  get 'javascript/confirm'
  get 'jscheck' => 'javascript#jscheck'

  get 'register'  => 'users#register'
  get 'apply'  => 'users#register'
  post 'create' => 'users#create'
  get 'login'  => 'users#login'
  get 'logout'  => 'users#logout'
  post 'auth'  => 'users#auth'
  get 'application'  => 'users#application'
  get 'app'  => 'users#application'
  get 'dashboard' => 'users#dashboard'
  get 'rsvp' => 'users#rsvp'
  post 'rsvp' => 'users#saversvp'
  get 'mycode' => 'users#usercode'
  get 'forgot'  => 'users#forgot'
  get 'sorry' => 'users#sorry'
  post 'requestreset'  => 'users#requestreset'
  post 'save' => 'users#save'
  resources :users

  get 'mentorship/register' => 'mentorship#registration'
  post 'mentorship/register' => 'mentorship#register'

  root :to => 'pages#index', :as => :index
  post 'subscribe' => 'pages#subscribe'
  get 'outage' => 'pages#outage'
  get 'winners2015' => 'pages#winners2015'
  get 'hangout' => 'pages#hangout'
  get 'tables' => 'pages#tables'
  get 'judging' => 'pages#judging'
  get 'map' => 'pages#map'

  get 'admin' => 'admin#admin'
  get 'admin/sponsorship' => 'admin#sponsorship'
  get 'admin/stats' => 'statistics#stats'
  get 'admin/statistics' => 'statistics#stats'
  get 'statistics' => 'statistics#stats'
  post 'admin/notifications' => 'admin#notifications'
  post 'admin/internal-notifications' => 'admin#internal_notifications'
  get 'admin/users/applications' => 'admin#applications'
  post 'admin/users/applications' => 'admin#app_status'
  get 'admin/users/rsvps' => 'admin#rsvps'
  get 'admin/users/email' => 'admin#email'
  post 'admin/users/email' => 'admin#send_emails'
  get 'admin/users/checkin' => 'admin#checkin'
  post '/admin/users/checkin-search' => 'admin#checkin_search'
  post '/admin/users/checkin-confirm' => 'admin#checkin_confirm'
  get '/admin/users/onsite-registration' => 'admin#onsite'
  post '/admin/users/onsite-search' => 'admin#onsite_search'
  post '/admin/users/onsite-submit' => 'admin#onsite_submit'
  post 'admin/users/generate' => 'admin#generate_code'
  get 'admin/internal/register' => 'admin#internal_register'
  post 'admin/internal/register' => 'admin#internal_register_submit'
  get 'admin/judging/register' => 'admin#judging_register'
  post 'admin/judging/register' => 'admin#judging_register_confirm'
  post 'addsponsor' => 'admin#addsponsor'
  post 'viewsponsor' => 'admin#viewsponsor'
  post 'editsponsor' => 'admin#editsponsor'

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
end
