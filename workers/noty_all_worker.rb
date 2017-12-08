class NotyAllWorker
  include Sidekiq::Worker
  def perform(attachments)
    urls = $homu_redis.smembers('webhooks')
    urls.each do |url|
      begin
        RestClient.post url, {
          attachments: attachments
        }.to_json
      rescue RestClient::NotFound => e
        $homu_redis.srem('webhooks', url)
      end
    end
  end
end
