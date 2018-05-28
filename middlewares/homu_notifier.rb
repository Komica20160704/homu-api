# frozen_string_literal: true

require 'faye/websocket'
require 'json'

module HomuApi
  class HomuNotifier
    KEEPALIVE_TIME = 15 # in seconds
    MAX_DATA_COUNT_S = ENV['MAX_DATA_COUNT'] || 50
    MAX_DATA_COUNT = MAX_DATA_COUNT_S.to_i

    def initialize(app)
      @app = app
      @redis = Redis::Namespace.new(:homu, redis: Redis.new)
      @clients = []
      @data = { 'Heads' => [], 'Blocks' => [], 'Type' => 'Cache' }
      cached_data = @redis.get 'data'
      @data.merge! JSON.parse cached_data if cached_data
    end

    def notify(data)
      @clients.each { |client| client.send(data.to_json) }
      log_data data
    end

    def log_data(data)
      @data['Heads'] = (@data['Heads'] + data['Heads']).uniq
      @data['Blocks'] += data['Blocks']
      max_data
      @redis.set 'data', @data.to_json
    end

    def max_data
      return if @data['Blocks'].size <= MAX_DATA_COUNT
      @data['Blocks'].shift(@data['Blocks'].size - MAX_DATA_COUNT)
      @data['Heads'] = gen_new_heads
    end

    def gen_new_heads
      new_heads = []
      @data['Heads'].each do |head|
        if @data['Blocks'].find { |block| block['HeadNo'] == head['No'] }
          new_heads << head
        end
      end
      new_heads
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        @ws = Faye::WebSocket.new(env, nil, ping: KEEPALIVE_TIME)
        on_open
        on_message
        on_close
        @ws.rack_response
      else
        env['WsClientCount'] = @clients.size
        @app.call(env)
      end
    end

    private

    def on_open
      @ws.on :open do |_event|
        @clients << @ws
        @ws.send @data.to_json
      end
    end

    def on_message
      @ws.on :message do |event|
        data = JSON.parse(event.data)
        if data['Event'] == 'Send'
          @clients.each { |client| client.send(event.data) }
        elsif data['Event'] == 'KeepAlive'
          next if @clients.include?(@ws)
          @ws.close
          @ws = nil
        end
      end
    end

    def on_close
      @ws.on :close do |_event|
        @clients.delete(@ws)
        @ws = nil
      end
    end
  end
end
