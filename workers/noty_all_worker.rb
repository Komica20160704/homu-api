class NotyAllWorker
  include Sidekiq::Worker
  def perform(attachments)
    urls = $homu_redis.smembers('webhooks')
    urls.each do |url|
      begin
        RestClient.post url, {
          attachments: attachments
        }.to_json
        $homu_redis.hdel('webhooks_results', url)
        $homu_redis.hdel('webhooks_error_count', url)
      rescue RestClient::NotFound => e
        $homu_redis.srem('webhooks', url)
      rescue Exception => e
        $homu_redis.hset('webhooks_results', url, e.message)
        count = $homu_redis.hincrby('webhooks_error_count', url, 1)
        if count >= 5
          $homu_redis.srem('webhooks', url)
          $homu_redis.hdel('webhooks_results', url)
          $homu_redis.hdel('webhooks_error_count', url)
        end
      end
    end
  end
end
