if ENV["BITCOIN_ZMQ_ENABLED"] == "true" && !Rails.env.test?
  Rails.application.config.after_initialize do
    ZmqListener.start
  end
end
