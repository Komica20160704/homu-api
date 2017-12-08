class NotyAllWorker
  include Sidekiq::Worker
  def perform(block)
    @block = block
    return if message.nil?
    urls = $homu_redis.smembers('webhooks')
    urls.each do |url|
      begin
        RestClient.post url, {
          text: message,
        }.to_json
      rescue RestClient::NotFound => e
        $homu_redis.srem('webhooks', url)
      end
    end
  end

  def message
    @message ||= begin
      if @block['Content']
        result = "#{@block['Title']} #{@block['Name']} #{@block['Date']} #{@block['Time']} ID:#{@block['ID']} No.#{@block['No']}}\n"
        result += "Picture: #{@block['Picture']}\n" if @block['Picture']
        result += @block['Content']
        result
      end
    end
  end
end
