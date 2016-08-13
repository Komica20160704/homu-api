require 'sinatra/base'

module HomuApi
  class App < Sinatra::Base
    get "/" do
      count = request.env['WsClientCount']
      erb :index, :locals => { :css_list => ['index.css'], :ws_client_count => count }
    end

    run! if app_file == $0
  end
end
