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
    end

    def notify(data)
      @clients.each { |client| client.send(data.to_json) }
      log_data data
      if data['Type'] == 'Notify' && !data['Blocks'].nil?
        noty_all(data)
      end
    end

    def noty_all(data)
      attachments = data['Blocks'].map do |block|
        attachemnt = {
          fallback: message(block),
          color: '#F0E0D6',
          author_name: block['Name'],
          title: block['Title'],
          title_link: "http://rem.komica2.net/00/pixmicat.php?res=#{block['No']}",
          text: block['Content'],
          ts: Time.parse("#{block['Date']} #{block['Time']} +0800").to_i,
        }
        if block['HeadNo'] != block['No']
          head = data['Blocks'].find { |head| head['No'] == block['HeadNo'] }
          attachemnt[:pretext] = head['Content'].lines.first
        end
        if block['Picture']
          attachemnt[:image_url] = "http://p2.komica.ml/00/src/#{block['Picture']}"
          attachemnt[:thumb_url] = "http://p2.komica.ml/00/thumb/#{block['Picture'].split('.').first}s.jpg"
        end
      end
    end

    def message(block)
      result = "#{block['Title']} #{block['Name']} #{block['Date']} #{block['Time']} ID:#{block['Id']} No.#{block['No']}\n"
      result += "http://p2.komica.ml/00/thumb/#{block['Picture'].split('.').first}s.jpg\n" if block['Picture']
      result += block['Content']
      result
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
