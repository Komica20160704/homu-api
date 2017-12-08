require 'rest-client'

class SayHiWorker
  include Sidekiq::Worker
  def perform(url)
    $homu_redis.sadd('webhooks', url)
    RestClient.post url, {
      text: 'Just say hi!',
    }.to_json
  end
end
