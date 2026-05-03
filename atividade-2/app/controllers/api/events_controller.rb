module Api
  class EventsController < ActionController::API
    def summary
      render json: ZmqEventStore.summary
    end
  end
end
