require "bigdecimal"

class MempoolSummary
  LOW_THRESHOLD    = BigDecimal("10")
  HIGH_THRESHOLD   = BigDecimal("50")

  def initialize(rpc_client = BitcoinRpcClient.new)
    @rpc = rpc_client
  end

  def call
    info = @rpc.call("getmempoolinfo")

    return empty_summary if info["size"].zero?

    raw_mempool = @rpc.call("getrawmempool", [true])
    fee_rates   = collect_fee_rates(raw_mempool)

    return empty_summary if fee_rates.empty?

    {
      tx_count:         info["size"],
      total_vsize:      total_vsize(raw_mempool),
      avg_fee_rate:     avg(fee_rates).round(2).to_f,
      min_fee_rate:     fee_rates.min.round(2).to_f,
      max_fee_rate:     fee_rates.max.round(2).to_f,
      fee_distribution: distribute(fee_rates)
    }
  end

  private

  def collect_fee_rates(raw_mempool)
    raw_mempool.filter_map do |_txid, tx|
      size = tx["vsize"] || tx["size"]
      next if size.nil? || size.zero?

      fee_btc = tx["fees"]&.fetch("base", nil) || tx["fee"]
      next if fee_btc.nil?

      BigDecimal(fee_btc.to_s) * 100_000_000 / size
    end
  end

  def total_vsize(raw_mempool)
    raw_mempool.sum { |_, tx| tx["vsize"] || tx["size"] || 0 }
  end

  def avg(values)
    values.sum / values.size
  end

  def distribute(fee_rates)
    counts = { low: 0, medium: 0, high: 0 }

    fee_rates.each do |rate|
      counts[:high]   += 1 and next if rate > HIGH_THRESHOLD
      counts[:medium] += 1 and next if rate >= LOW_THRESHOLD
      counts[:low]    += 1
    end

    counts
  end

  def empty_summary
    {
      tx_count:         0,
      total_vsize:      0,
      avg_fee_rate:     0,
      min_fee_rate:     0,
      max_fee_rate:     0,
      fee_distribution: { low: 0, medium: 0, high: 0 }
    }
  end
end
