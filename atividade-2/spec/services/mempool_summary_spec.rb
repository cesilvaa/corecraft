require "rails_helper"

RSpec.describe MempoolSummary do
  let(:rpc) { instance_double(BitcoinRpcClient) }
  subject(:summary) { described_class.new(rpc).call }

  context "when mempool is empty" do
    before { allow(rpc).to receive(:call).with("getmempoolinfo").and_return({ "size" => 0 }) }

    it "returns zeroed summary without calling getrawmempool" do
      expect(rpc).not_to receive(:call).with("getrawmempool", [true])
      expect(summary).to eq(
        tx_count: 0, total_vsize: 0, avg_fee_rate: 0,
        min_fee_rate: 0, max_fee_rate: 0,
        fee_distribution: { low: 0, medium: 0, high: 0 }
      )
    end
  end

  context "with transactions" do
    let(:raw_mempool) do
      {
        "aaa" => { "fees" => { "base" => 0.00000050 }, "vsize" => 10 },  # 5 sat/vB  → low
        "bbb" => { "fees" => { "base" => 0.00000200 }, "vsize" => 10 },  # 20 sat/vB → medium
        "ccc" => { "fees" => { "base" => 0.00000600 }, "vsize" => 10 }   # 60 sat/vB → high
      }
    end

    before do
      allow(rpc).to receive(:call).with("getmempoolinfo").and_return({ "size" => 3 })
      allow(rpc).to receive(:call).with("getrawmempool", [true]).and_return(raw_mempool)
    end

    it "uses tx_count from getmempoolinfo" do
      expect(summary[:tx_count]).to eq(3)
    end

    it "calculates total_vsize" do
      expect(summary[:total_vsize]).to eq(30)
    end

    it "calculates avg_fee_rate" do
      expect(summary[:avg_fee_rate]).to eq(28.33)
    end

    it "identifies min_fee_rate" do
      expect(summary[:min_fee_rate]).to eq(5.0)
    end

    it "identifies max_fee_rate" do
      expect(summary[:max_fee_rate]).to eq(60.0)
    end

    it "distributes transactions by fee tier" do
      expect(summary[:fee_distribution]).to eq(low: 1, medium: 1, high: 1)
    end
  end

  describe "fee classification" do
    def summary_for(fee_btc, vsize)
      txs = { "x" => { "fees" => { "base" => fee_btc }, "vsize" => vsize } }
      allow(rpc).to receive(:call).with("getmempoolinfo").and_return({ "size" => 1 })
      allow(rpc).to receive(:call).with("getrawmempool", [true]).and_return(txs)
      described_class.new(rpc).call[:fee_distribution]
    end

    it "classifies < 10 sat/vB as low"    do expect(summary_for(0.00000090, 10)).to eq(low: 1, medium: 0, high: 0) end
    it "classifies 10 sat/vB as medium"   do expect(summary_for(0.00000100, 10)).to eq(low: 0, medium: 1, high: 0) end
    it "classifies 50 sat/vB as medium"   do expect(summary_for(0.00000500, 10)).to eq(low: 0, medium: 1, high: 0) end
    it "classifies > 50 sat/vB as high"   do expect(summary_for(0.00000510, 10)).to eq(low: 0, medium: 0, high: 1) end
  end

  describe "fee rate calculation" do
    before do
      txs = { "x" => { "fees" => { "base" => 0.00001000 }, "vsize" => 100 } }
      allow(rpc).to receive(:call).with("getmempoolinfo").and_return({ "size" => 1 })
      allow(rpc).to receive(:call).with("getrawmempool", [true]).and_return(txs)
    end

    it "converts BTC to satoshis and divides by vsize" do
      # 0.00001 BTC = 1000 sat, 1000 / 100 vB = 10 sat/vB
      expect(summary[:avg_fee_rate]).to eq(10.0)
    end
  end

  describe "robustness" do
    it "ignores transactions without valid size" do
      txs = {
        "valid"   => { "fees" => { "base" => 0.00000100 }, "vsize" => 10 },
        "no_size" => { "fees" => { "base" => 0.00000100 }, "vsize" => 0 }
      }
      allow(rpc).to receive(:call).with("getmempoolinfo").and_return({ "size" => 2 })
      allow(rpc).to receive(:call).with("getrawmempool", [true]).and_return(txs)
      expect(described_class.new(rpc).call[:tx_count]).to eq(2)
    end
  end
end
