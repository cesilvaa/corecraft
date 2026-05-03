class PanelController < ApplicationController
  def index
    rpc = BitcoinRpcClient.new
    @mempool = MempoolSummary.new(rpc).call
    @sync    = BlockchainLag.new(rpc).call
  rescue BitcoinRpcClient::ConnectionError
    @node_error = true
  end
end
