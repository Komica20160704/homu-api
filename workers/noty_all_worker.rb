class NotyAllWorker
  include Sidekiq::Worker
  def perform(message)
    urls = $homu_redis.smembers('webhooks')
    urls.each do |url|
      begin
        RestClient.post url, {
          text: message,
        }.to_json
      rescue Exception => e
        puts "url: #{url}, message: #{e.message}"
      end
    end
  end
end
