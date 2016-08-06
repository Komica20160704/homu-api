require 'sinatra/base'

module HomuApi
  class App < Sinatra::Base
    get "/" do
      erb :index, :locals => { :css_list => ['index.css'] }
    end

    run! if app_file == $0
  end
end
