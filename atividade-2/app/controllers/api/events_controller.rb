module Api
  class EventsController < ActionController::API
    def summary
      render json: ZmqEventStore.summary
    end

    def latest
      render json: ZmqEventStore.latest
    end

    def state_comparison
      render json: StateComparison.new.call
    rescue BitcoinRpcClient::ConnectionError => e
      render json: { error: "Node unavailable", detail: e.message }, status: :service_unavailable
    rescue BitcoinRpcClient::RpcError => e
      render json: { error: "RPC error", detail: e.message }, status: :bad_gateway
    end
  end
end
