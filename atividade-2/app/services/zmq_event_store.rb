module ZmqEventStore
  MAX_BLOCKS     = 50
  MAX_TXS        = 500
  WINDOW_SECONDS = 60
  LATEST_BLOCKS  = 10
  LATEST_TXS     = 25

  @mutex  = Mutex.new
  @blocks = []
  @txs    = []

  module_function

  def push_block(hash)
    @mutex.synchronize do
      @blocks << { hash: hash, at: Time.now.to_i }
      @blocks.shift if @blocks.size > MAX_BLOCKS
    end
  end

  def push_tx(txid)
    @mutex.synchronize do
      @txs << { txid: txid, at: Time.now.to_i }
      @txs.shift if @txs.size > MAX_TXS
    end
  end

  def summary
    @mutex.synchronize do
      now    = Time.now.to_i
      cutoff = now - WINDOW_SECONDS

      recent_tx_count = @txs.count { |e| e[:at] >= cutoff }
      last_event_at   = [ @blocks.last&.dig(:at), @txs.last&.dig(:at) ].compact.max

      {
        blocks_observed: @blocks.size,
        tx_observed:     @txs.size,
        last_event_time: last_event_at,
        tx_per_second:   (recent_tx_count.to_f / WINDOW_SECONDS).round(2)
      }
    end
  end

  def latest
    @mutex.synchronize do
      {
        blocks: @blocks.last(LATEST_BLOCKS).map { |e| { hash: e[:hash], ts: e[:at] } },
        txs:    @txs.last(LATEST_TXS).map    { |e| { txid: e[:txid], ts: e[:at] } }
      }
    end
  end

  def reset!
    @mutex.synchronize do
      @blocks.clear
      @txs.clear
    end
  end
end
