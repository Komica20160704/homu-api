class NotyAllWorker
  include Sidekiq::Worker
  def perform(message)
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
end
