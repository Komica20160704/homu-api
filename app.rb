require 'sinatra/base'

module HomuApi
  class App < Sinatra::Base
    get '/' do
      count = request.env['WsClientCount']
      bg = Dir.glob('./public/bgs/*.png').map { |i| File.basename i }.sample
      erb :index, locals: { css_list: ['index.css'], ws_client_count: count, bg: bg }
    end

    run! if app_file == $PROGRAM_NAME
  end
end
