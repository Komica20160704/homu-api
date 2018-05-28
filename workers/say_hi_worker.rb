# frozen_string_literal: true

require 'rest-client'

class SayHiWorker
  include Sidekiq::Worker
  def perform(url)
    RestClient.post url, {
      text: 'Just say hi!'
    }.to_json
  end
end
