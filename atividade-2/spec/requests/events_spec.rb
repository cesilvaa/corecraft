require "rails_helper"

RSpec.describe "GET /api/events/summary", type: :request do
  let(:mock_summary) do
    {
      blocks_observed: 3,
      tx_observed:     120,
      last_event_time: 1_712_345_678,
      tx_per_second:   4.2
    }
  end

  before do
    allow(ZmqEventStore).to receive(:summary).and_return(mock_summary)
  end

  it "returns 200 with the correct JSON structure" do
    get "/api/events/summary"

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body, symbolize_names: true)

    expect(body[:blocks_observed]).to eq(3)
    expect(body[:tx_observed]).to eq(120)
    expect(body[:last_event_time]).to eq(1_712_345_678)
    expect(body[:tx_per_second]).to eq(4.2)
  end

  it "returns all required keys" do
    get "/api/events/summary"

    body = JSON.parse(response.body, symbolize_names: true)
    expect(body.keys).to contain_exactly(
      :blocks_observed, :tx_observed, :last_event_time, :tx_per_second
    )
  end
end
