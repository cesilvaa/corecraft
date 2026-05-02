require "rails_helper"

RSpec.describe "GET /panel", type: :request do
  let(:mock_mempool) do
    {
      tx_count: 3, total_vsize: 300, avg_fee_rate: 28.33,
      min_fee_rate: 5.0, max_fee_rate: 60.0,
      fee_distribution: { low: 1, medium: 1, high: 1 }
    }
  end

  let(:mock_sync) { { blocks: 116534, headers: 302552, lag: 186018 } }

  before do
    allow(MempoolSummary).to receive(:new).and_return(instance_double(MempoolSummary, call: mock_mempool))
    allow(BlockchainLag).to receive(:new).and_return(instance_double(BlockchainLag, call: mock_sync))
  end

  it "returns 200" do
    get "/panel"
    expect(response).to have_http_status(:ok)
  end

  it "renders mempool transaction count" do
    get "/panel"
    expect(response.body).to include("3")
  end

  it "renders avg fee rate" do
    get "/panel"
    expect(response.body).to include("28.33")
  end

  it "renders lag between headers and blocks" do
    get "/panel"
    expect(response.body).to include("186")
  end

  context "when node is unavailable" do
    before do
      allow(MempoolSummary).to receive(:new).and_raise(
        BitcoinRpcClient::ConnectionError, "connection refused"
      )
    end

    it "returns 200 with error message" do
      get "/panel"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("unavailable")
    end
  end
end
