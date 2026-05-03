require "net/http"
require "uri"
require "json"

class BitcoinRpcClient
  class RpcError < StandardError; end
  class ConnectionError < StandardError; end

  def initialize
    @host     = ENV.fetch("BITCOIN_RPC_HOST", "localhost")
    @port     = ENV.fetch("BITCOIN_RPC_PORT", "18443").to_i
    @user     = ENV.fetch("BITCOIN_RPC_USER")
    @password = ENV.fetch("BITCOIN_RPC_PASSWORD")
  end

  def call(method, params = [])
    uri = URI::HTTP.build(host: @host, port: @port, path: "/")

    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@user, @password)
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(jsonrpc: "1.0", id: "corecraft", method: method, params: params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 5
    http.read_timeout = 30

    response = http.request(request)
    parsed = JSON.parse(response.body)

    if parsed["error"]
      raise RpcError, "RPC error #{parsed['error']['code']}: #{parsed['error']['message']}"
    end

    parsed["result"]
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    raise ConnectionError, "Cannot connect to Bitcoin node at #{@host}:#{@port} — #{e.message}"
  rescue JSON::ParserError => e
    raise RpcError, "Invalid JSON from RPC: #{e.message}"
  end
end
