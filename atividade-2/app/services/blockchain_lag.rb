class BlockchainLag
  def initialize(rpc_client = BitcoinRpcClient.new)
    @rpc = rpc_client
  end

  def call
    info = @rpc.call("getblockchaininfo")

    blocks  = info["blocks"]
    headers = info["headers"]

    { blocks: blocks, headers: headers, lag: headers - blocks }
  end
end
