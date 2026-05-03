require "rails_helper"

RSpec.describe "GET /api/mempool/summary", type: :request do
  let(:mock_summary) do
    {
      tx_count: 3, total_vsize: 300, avg_fee_rate: 28.33,
      min_fee_rate: 5.0, max_fee_rate: 60.0,
      fee_distribution: { low: 1, medium: 1, high: 1 }
    }
  end

  before do
    service = instance_double(MempoolSummary, call: mock_summary)
    allow(MempoolSummary).to receive(:new).and_return(service)
  end

  it "returns 200 with the correct JSON structure" do
    get "/api/mempool/summary"

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body, symbolize_names: true)

    expect(body[:tx_count]).to eq(3)
    expect(body[:fee_distribution]).to eq(low: 1, medium: 1, high: 1)
  end

  context "when node is unavailable" do
    before do
      allow(MempoolSummary).to receive(:new).and_raise(
        BitcoinRpcClient::ConnectionError, "connection refused"
      )
    end

    it "returns 503" do
      get "/api/mempool/summary"
      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
