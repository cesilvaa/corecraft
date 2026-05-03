class PanelController < ApplicationController
  def index
    @event_summary = ZmqEventStore.summary
    @event_latest  = ZmqEventStore.latest

    rpc = BitcoinRpcClient.new
    @mempool          = MempoolSummary.new(rpc).call
    @sync             = BlockchainLag.new(rpc).call
    @state_comparison = StateComparison.new(rpc).call
  rescue BitcoinRpcClient::ConnectionError
    @node_error = true
  end
end
