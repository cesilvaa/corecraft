module Api
  class EventsController < ActionController::API
    def summary
      render json: ZmqEventStore.summary
    end

    def latest
      render json: ZmqEventStore.latest
    end
  end
end
