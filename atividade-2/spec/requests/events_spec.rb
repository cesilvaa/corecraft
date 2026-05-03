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

RSpec.describe "GET /api/events/latest", type: :request do
  let(:mock_latest) do
    {
      blocks: [
        { hash: "abc...", ts: 1_712_345_600 },
        { hash: "def...", ts: 1_712_345_678 }
      ],
      txs: [
        { txid: "tx1...", ts: 1_712_345_670 },
        { txid: "tx2...", ts: 1_712_345_675 },
        { txid: "tx3...", ts: 1_712_345_678 }
      ]
    }
  end

  before do
    allow(ZmqEventStore).to receive(:latest).and_return(mock_latest)
  end

  it "returns 200 with blocks and txs arrays" do
    get "/api/events/latest"

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body, symbolize_names: true)

    expect(body[:blocks].size).to eq(2)
    expect(body[:txs].size).to eq(3)
  end

  it "returns blocks with hash and ts" do
    get "/api/events/latest"
    block = JSON.parse(response.body, symbolize_names: true)[:blocks].first
    expect(block.keys).to contain_exactly(:hash, :ts)
  end

  it "returns txs with txid and ts" do
    get "/api/events/latest"
    tx = JSON.parse(response.body, symbolize_names: true)[:txs].first
    expect(tx.keys).to contain_exactly(:txid, :ts)
  end
end

RSpec.describe "GET /api/events/state-comparison", type: :request do
  let(:best_hash) { "000000000000000000024a4e" }
  let(:seen_hash) { "aabbccddeeff001122334455" }

  describe "when RPC is available" do
    before do
      service = instance_double(StateComparison)
      allow(StateComparison).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(
        best_block: best_hash, last_seen_block: seen_hash, divergence: true
      )
    end

    it "returns 200 with the correct JSON structure" do
      get "/api/events/state-comparison"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body, symbolize_names: true)

      expect(body[:best_block]).to eq(best_hash)
      expect(body[:last_seen_block]).to eq(seen_hash)
      expect(body[:divergence]).to be true
    end

    it "returns all required keys" do
      get "/api/events/state-comparison"
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body.keys).to contain_exactly(:best_block, :last_seen_block, :divergence)
    end
  end

  context "when node is unavailable" do
    before do
      allow(StateComparison).to receive(:new).and_raise(
        BitcoinRpcClient::ConnectionError, "connection refused"
      )
    end

    it "returns 503" do
      get "/api/events/state-comparison"
      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
