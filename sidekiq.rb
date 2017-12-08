require 'sidekiq'
require 'sidekiq/web'

class SayHiWorker
  include Sidekiq::Worker
  def perform(url)
    RestClient.post url, {
      text: 'Just say hi!',
    }.to_json
  end
end
