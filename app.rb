# encoding: utf-8
require 'sinatra/base'
require './helper/homu_getter'

module HomuApi
  class App < Sinatra::Base
    get '/kumiko' do
      erb :kumiko, layout: '<%= yield %>'
    end

    get '/' do
      count = request.env['WsClientCount']
      bg = Dir.glob('./public/bgs/*.png').map { |i| File.basename i }.sample
      erb :index, locals: { css_list: ['index.css'], ws_client_count: count, bg: bg }
    end

    get '/:headNo' do |headNo|
      content_type :json
      HomuGetter::get_res headNo
    end

    run! if app_file == $PROGRAM_NAME
  end
end
