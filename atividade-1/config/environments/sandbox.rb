require "active_support/core_ext/integer/time"

# Sandbox environment — connects to signet node.
Rails.application.configure do
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "sandbox_secret_key_base_only_for_local_dev_not_for_production")
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  config.active_support.deprecation = :log
  config.active_job.verbose_enqueue_logs = true
  config.action_dispatch.verbose_redirect_logs = true
  config.assets.quiet = true
  config.action_controller.raise_on_missing_callback_actions = true
  config.hosts = [
    "localhost",
    "ideology-reverse-haste.ngrok-free.dev"
  ]
end
