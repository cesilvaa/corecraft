require "ffi-rzmq"

class ZmqListener
  RECONNECT_DELAY = 5

  def start
    Thread.new { run }
  end

  private

  def run
    loop do
      attempt_connection
    rescue => e
      Rails.logger.error "[ZmqListener] #{e.class}: #{e.message} — reconnecting in #{RECONNECT_DELAY}s"
      sleep RECONNECT_DELAY
    end
  end

  def attempt_connection
    context = ZMQ::Context.new
    socket  = context.socket(ZMQ::SUB)
    socket.connect(endpoint)
    socket.setsockopt(ZMQ::SUBSCRIBE, "hashtx")
    socket.setsockopt(ZMQ::SUBSCRIBE, "hashblock")

    Rails.logger.info "[ZmqListener] Connected to #{endpoint}"

    loop do
      parts = []
      socket.recv_strings(parts)
      handle(parts)
    end
  ensure
    socket&.close
    context&.terminate
  end

  def handle(parts)
    topic, data, _sequence = parts
    return unless topic && data

    hex = data.unpack1("H*")

    case topic
    when "hashtx"    then ZmqEventStore.push_tx(hex)
    when "hashblock" then ZmqEventStore.push_block(hex)
    end
  end

  def endpoint
    host = ENV.fetch("BITCOIN_ZMQ_HOST", "ubuntu")
    port = ENV.fetch("BITCOIN_ZMQ_PORT", "28332")
    "tcp://#{host}:#{port}"
  end
end
