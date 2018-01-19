require 'faye/websocket'
require 'json'

module HomuApi
  class HomuNotifier
    KEEPALIVE_TIME = 15 # in seconds
    MAX_DATA_COUNT_S = ENV['MAX_DATA_COUNT'] || 50
    MAX_DATA_COUNT = MAX_DATA_COUNT_S.to_i

    def initialize(app)
      @app = app
      @clients = []
      @data = { 'Heads' => [], 'Blocks' => [], 'Type' => 'Cache' }
      cached_data = $homu_redis.get 'data'
      if cached_data
        @data.merge! JSON.parse cached_data
      end
    end

    def notify(data)
      @clients.each { |client| client.send(data.to_json) }
      log_data data
    end

    def log_data(data)
      @data['Heads'] = (@data['Heads'] + data['Heads']).uniq
      @data['Blocks'] += data['Blocks']
      if @data['Blocks'].size > MAX_DATA_COUNT
        new_heads = []
        @data['Blocks'].shift(@data['Blocks'].size - MAX_DATA_COUNT)
        @data['Heads'].each do |head|
          if @data['Blocks'].find { |b| b['HeadNo'] == head['No'] }
            new_heads << head
          end
        end
        @data['Heads'] = new_heads
      end
      $homu_redis.set 'data', @data.to_json
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        # WebSockets logic goes here
        ws = Faye::WebSocket.new(env, nil, ping: KEEPALIVE_TIME)

        ws.on :open do |event|
          @clients << ws
          ws.send @data.to_json
        end

        ws.on :message do |event|
          data = JSON.parse(event.data)
          if data['Event'] == 'Send'
            @clients.each { |client| client.send(event.data) }
          elsif data['Event'] == 'KeepAlive'
            unless @clients.include?(ws)
              ws.close
              ws = nil
            end
          end
        end

        ws.on :close do |event|
          @clients.delete(ws)
          ws = nil
        end

        # Return async Rack response
        ws.rack_response
      else
        env['WsClientCount'] = @clients.size
        @app.call(env)
      end
    end
  end
end
