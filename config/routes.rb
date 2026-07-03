# =============================================================================
# config/routes.rb
# =============================================================================

Rails.application.routes.draw do
  # Health check used by Docker and load balancers
  get "/health", to: "health#show"

  # Sidekiq Web UI
  # Development: open access. Production: HTTP Basic Auth via env vars.
  require "sidekiq/web"
  if Rails.env.development?
    mount Sidekiq::Web => "/sidekiq"
  elsif Rails.env.production? && ENV["SIDEKIQ_USERNAME"].present? && ENV["SIDEKIQ_PASSWORD"].present?
    sidekiq_username = ENV.fetch("SIDEKIQ_USERNAME", nil)
    sidekiq_password = ENV.fetch("SIDEKIQ_PASSWORD", nil)

    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username_ok = ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(username),
        Digest::SHA256.hexdigest(sidekiq_username)
      )
      password_ok = ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(password),
        Digest::SHA256.hexdigest(sidekiq_password)
      )

      username_ok && password_ok
    end
    mount Sidekiq::Web => "/sidekiq"
  end

  # PWA routes (Rails 8)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root
  # root "home#index"

  # Define your routes here:
  # resources :articles
  # namespace :api do
  #   namespace :v1 do
  #     resources :users
  #   end
  # end
end
