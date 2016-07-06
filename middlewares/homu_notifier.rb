require 'faye/websocket'
require 'json'

module HomuApi
  class HomuNotifier
    FILE_PATH = './public/data.txt' # for save and load
    KEEPALIVE_TIME = 15 # in seconds
    MAX_DATA_COUNT = 10

    def initialize(app)
      @app = app
      @clients = []
      @data = { 'Heads' => [], 'Blocks' => [], 'Type' => 'Notify' }
      load_data
      ObjectSpace.define_finalizer(self, proc {|id| save_data })
    end

    def notify(data)
      @clients.each { |client| client.send(data.to_json) }
      log_data data
    end

    def log_data data
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
    end

    def load_data
      if File.exist? FILE_PATH
        text = File.read FILE_PATH
        @data = JSON.parse text
      end
    end

    def save_data
      File.write FILE_PATH, @data.to_json
      @clients.each do |client|
        client.close
        client = nil
      end
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        # WebSockets logic goes here
        ws = Faye::WebSocket.new(env, nil, { ping: KEEPALIVE_TIME })

        ws.on :open do |event|
          # p [:open, ws.object_id]
          @clients << ws
          ws.send @data.to_json
        end

        ws.on :message do |event|
          # p [:message, event.data]
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
          # p [:close, ws.object_id, event.code, event.reason]
          @clients.delete(ws)
          ws = nil
        end

        # Return async Rack response
        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end
