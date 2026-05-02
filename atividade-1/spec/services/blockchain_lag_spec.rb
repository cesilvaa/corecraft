require "rails_helper"

RSpec.describe BlockchainLag do
  let(:rpc) { instance_double(BitcoinRpcClient) }
  subject(:result) { described_class.new(rpc).call }

  before do
    allow(rpc).to receive(:call).with("getblockchaininfo").and_return(
      "blocks" => 116534, "headers" => 302552
    )
  end

  it "returns blocks from getblockchaininfo" do
    expect(result[:blocks]).to eq(116534)
  end

  it "returns headers from getblockchaininfo" do
    expect(result[:headers]).to eq(302552)
  end

  it "calculates lag as headers minus blocks" do
    expect(result[:lag]).to eq(186018)
  end

  context "when node is fully synced" do
    before do
      allow(rpc).to receive(:call).with("getblockchaininfo").and_return(
        "blocks" => 302552, "headers" => 302552
      )
    end

    it "returns lag of zero" do
      expect(result[:lag]).to eq(0)
    end
  end
end
