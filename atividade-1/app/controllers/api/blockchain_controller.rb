module Api
  class BlockchainController < ActionController::API
    def lag
      result = BlockchainLag.new.call
      render json: result
    rescue BitcoinRpcClient::ConnectionError => e
      render json: { error: "Node unavailable", detail: e.message }, status: :service_unavailable
    rescue BitcoinRpcClient::RpcError => e
      render json: { error: "RPC error", detail: e.message }, status: :bad_gateway
    end
  end
end
