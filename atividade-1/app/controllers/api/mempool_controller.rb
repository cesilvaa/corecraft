module Api
  class MempoolController < ApplicationController
    skip_before_action :verify_authenticity_token

    def summary
      result = MempoolSummary.new.call
      render json: result
    rescue BitcoinRpcClient::ConnectionError => e
      render json: { error: "Node unavailable", detail: e.message }, status: :service_unavailable
    rescue BitcoinRpcClient::RpcError => e
      render json: { error: "RPC error", detail: e.message }, status: :bad_gateway
    end
  end
end
