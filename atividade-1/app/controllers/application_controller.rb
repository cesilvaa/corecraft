class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  def status
    render json: {
      status: "ok",
      app: "corecraft-v1",
      rails: Rails.version,
      ruby: RUBY_VERSION,
      env: Rails.env,
      network: ENV.fetch("BITCOIN_RPC_NETWORK", "not configured")
    }
  end
end
