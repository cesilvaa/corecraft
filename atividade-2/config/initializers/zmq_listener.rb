if ENV["BITCOIN_ZMQ_ENABLED"] == "true" && !Rails.env.test?
  Rails.application.config.to_prepare do
    ZmqListener.start
  end
end
