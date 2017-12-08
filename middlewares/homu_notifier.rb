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

          author_name: block['Name'],
          title: block['Title'],
          text: "#{block['Content']}",
          ts: Time.parse("#{block['Date']} #{block['Time']} +0800").to_i,
        }
        if block['HeadNo'] != block['No']
          head = data['Heads'].find { |head| head['No'] == block['HeadNo'] }
          attachemnt[:pretext] = "#{block['Id']}回應了<http://rem.komica2.net/00/pixmicat.php?res=#{block['HeadNo']}|討論串>"
          attachemnt[:author_name] = "No.#{head['No']} ID:#{head['Id']}: #{head['Content'].gsub("\n", ' ').first[0..8]}⋯⋯\n"
          attachemnt[:color] = '#f0e0d6'
        else
          attachemnt[:pretext] = "#{block['Id']}發了一篇<http://rem.komica2.net/00/pixmicat.php?res=#{block['HeadNo']}|新文章>"
          attachemnt[:color] = '#ffffee'
        end
        if block['Picture']
          attachemnt[:image_url] = "http://p2.komica.ml/00/src/#{block['Picture']}"
          attachemnt[:thumb_url] = "http://p2.komica.ml/00/thumb/#{block['Picture'].split('.').first}s.jpg"
        end
        attachemnt
      end
      NotyAllWorker.perform_async attachments
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
