require "rails_helper"

RSpec.describe "GET /panel", type: :request do
  let(:mock_mempool) do
    {
      tx_count: 3, total_vsize: 300, avg_fee_rate: 28.33,
      min_fee_rate: 5.0, max_fee_rate: 60.0,
      fee_distribution: { low: 1, medium: 1, high: 1 }
    }
  end

  let(:mock_sync)       { { blocks: 116534, headers: 302552, lag: 186018 } }
  let(:mock_comparison) { { best_block: "abc123", last_seen_block: "abc123", divergence: false } }
  let(:mock_event_summary) do
    { blocks_observed: 2, tx_observed: 45, tx_per_second: 0.75, last_event_time: 1_712_345_678 }
  end
  let(:mock_event_latest) do
    {
      blocks: [ { hash: "blockhash1", ts: 1_712_345_600 } ],
      txs:    [ { txid: "txid1",      ts: 1_712_345_670 } ]
    }
  end

  before do
    allow(MempoolSummary).to receive(:new).and_return(instance_double(MempoolSummary, call: mock_mempool))
    allow(BlockchainLag).to receive(:new).and_return(instance_double(BlockchainLag, call: mock_sync))
    allow(StateComparison).to receive(:new).and_return(instance_double(StateComparison, call: mock_comparison))
    allow(ZmqEventStore).to receive(:summary).and_return(mock_event_summary)
    allow(ZmqEventStore).to receive(:latest).and_return(mock_event_latest)
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

  it "renders event activity stats" do
    get "/panel"
    expect(response.body).to include("Event Activity")
    expect(response.body).to include("45")
    expect(response.body).to include("0.75")
  end

  it "renders the últimos eventos card" do
    get "/panel"
    expect(response.body).to include("Últimos Eventos")
    expect(response.body).to include("blockhash1")
    expect(response.body).to include("txid1")
  end

  it "renders the divergence banner as ok when in sync" do
    get "/panel"
    expect(response.body).to include("divergence-banner--ok")
    expect(response.body).to include("ZMQ and RPC in sync")
  end

  it "renders the divergence banner as alert when diverged" do
    allow(StateComparison).to receive(:new).and_return(
      instance_double(StateComparison, call: { best_block: "aaa", last_seen_block: "bbb", divergence: true })
    )
    get "/panel"
    expect(response.body).to include("divergence-banner--alert")
    expect(response.body).to include("Block divergence detected")
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
