class StateComparison
  def initialize(rpc_client = BitcoinRpcClient.new)
    @rpc = rpc_client
  end

  def call
    best_block      = @rpc.call("getbestblockhash")
    last_seen_block = ZmqEventStore.latest[:blocks].last&.dig(:hash)

    {
      best_block:      best_block,
      last_seen_block: last_seen_block,
      divergence:      best_block != last_seen_block
    }
  end
end
