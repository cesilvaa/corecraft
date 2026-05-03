require "rails_helper"

RSpec.describe ZmqEventStore do
  before { described_class.reset! }

  describe ".push_block" do
    it "records a block event" do
      described_class.push_block("000abc")
      expect(described_class.summary[:blocks_observed]).to eq(1)
    end

    it "caps the buffer at MAX_BLOCKS" do
      (ZmqEventStore::MAX_BLOCKS + 5).times { |i| described_class.push_block("hash#{i}") }
      expect(described_class.summary[:blocks_observed]).to eq(ZmqEventStore::MAX_BLOCKS)
    end
  end

  describe ".push_tx" do
    it "records a tx event" do
      described_class.push_tx("txid001")
      expect(described_class.summary[:tx_observed]).to eq(1)
    end

    it "caps the buffer at MAX_TXS" do
      (ZmqEventStore::MAX_TXS + 10).times { |i| described_class.push_tx("tx#{i}") }
      expect(described_class.summary[:tx_observed]).to eq(ZmqEventStore::MAX_TXS)
    end
  end

  describe ".summary" do
    it "returns zero counts when store is empty" do
      result = described_class.summary

      expect(result[:blocks_observed]).to eq(0)
      expect(result[:tx_observed]).to eq(0)
      expect(result[:last_event_time]).to be_nil
      expect(result[:tx_per_second]).to eq(0.0)
    end

    it "returns the expected keys" do
      expect(described_class.summary.keys).to contain_exactly(
        :blocks_observed, :tx_observed, :last_event_time, :tx_per_second
      )
    end

    it "reflects pushed blocks and txs" do
      described_class.push_block("blockA")
      described_class.push_tx("tx1")
      described_class.push_tx("tx2")

      result = described_class.summary
      expect(result[:blocks_observed]).to eq(1)
      expect(result[:tx_observed]).to eq(2)
    end

    it "sets last_event_time to the most recent event timestamp" do
      freeze_time = Time.now.to_i
      allow(Time).to receive(:now).and_return(Time.at(freeze_time))

      described_class.push_tx("txA")

      expect(described_class.summary[:last_event_time]).to eq(freeze_time)
    end

    it "calculates tx_per_second over the last WINDOW_SECONDS" do
      now = Time.now.to_i

      allow(Time).to receive(:now).and_return(Time.at(now))
      30.times { described_class.push_tx("tx_new") }

      allow(Time).to receive(:now).and_return(Time.at(now - ZmqEventStore::WINDOW_SECONDS - 1))
      5.times { described_class.push_tx("tx_old") }

      allow(Time).to receive(:now).and_return(Time.at(now))

      expected = (30.0 / ZmqEventStore::WINDOW_SECONDS).round(2)
      expect(described_class.summary[:tx_per_second]).to eq(expected)
    end
  end
end
