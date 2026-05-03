require "rails_helper"

RSpec.describe StateComparison do
  let(:rpc)    { instance_double(BitcoinRpcClient) }
  let(:hash_a) { "000000000000000000024a4e9d9a5b1f2e3c4d5e6f7a8b9c" }
  let(:hash_b) { "aabbccddeeff00112233445566778899aabbccddeeff0011" }

  subject(:service) { described_class.new(rpc) }

  before { ZmqEventStore.reset! }

  describe "#call" do
    context "when ZMQ and RPC agree on the best block" do
      before do
        allow(rpc).to receive(:call).with("getbestblockhash").and_return(hash_a)
        ZmqEventStore.push_block(hash_a)
      end

      it "returns divergence: false" do
        expect(service.call[:divergence]).to be false
      end

      it "returns the same hash for best_block and last_seen_block" do
        result = service.call
        expect(result[:best_block]).to eq(hash_a)
        expect(result[:last_seen_block]).to eq(hash_a)
      end
    end

    context "when ZMQ and RPC report different blocks" do
      before do
        allow(rpc).to receive(:call).with("getbestblockhash").and_return(hash_a)
        ZmqEventStore.push_block(hash_b)
      end

      it "returns divergence: true" do
        expect(service.call[:divergence]).to be true
      end

      it "returns each hash in its respective field" do
        result = service.call
        expect(result[:best_block]).to eq(hash_a)
        expect(result[:last_seen_block]).to eq(hash_b)
      end
    end

    context "when no block has been seen via ZMQ yet" do
      before do
        allow(rpc).to receive(:call).with("getbestblockhash").and_return(hash_a)
      end

      it "returns last_seen_block as nil" do
        expect(service.call[:last_seen_block]).to be_nil
      end

      it "returns divergence: true" do
        expect(service.call[:divergence]).to be true
      end
    end
  end
end
