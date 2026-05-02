require "rails_helper"

RSpec.describe "GET /api/blockchain/lag", type: :request do
  let(:mock_result) do
    { blocks: 116534, headers: 302552, lag: 186018 }
  end

  before do
    service = instance_double(BlockchainLag, call: mock_result)
    allow(BlockchainLag).to receive(:new).and_return(service)
  end

  it "returns 200 with the correct JSON structure" do
    get "/api/blockchain/lag"

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body, symbolize_names: true)

    expect(body[:blocks]).to eq(116534)
    expect(body[:headers]).to eq(302552)
    expect(body[:lag]).to eq(186018)
  end

  context "when node is unavailable" do
    before do
      allow(BlockchainLag).to receive(:new).and_raise(
        BitcoinRpcClient::ConnectionError, "connection refused"
      )
    end

    it "returns 503" do
      get "/api/blockchain/lag"
      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
