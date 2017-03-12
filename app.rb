# encoding: utf-8
require 'sinatra/base'
require "sinatra/reloader"
require './helper/homu_getter'

module HomuApi
  class App < Sinatra::Base
    configure :development do
      register Sinatra::Reloader
    end

    get '/kumiko' do
      erb :kumiko, layout: '<%= yield %>'
    end

    get '/' do
      view_erb :index
    end

    get '/follow/:resNo' do |resNo|
      view_erb(:follow, locals: { resNo: resNo })
    end

    get '/:headNo' do |headNo|
      content_type :json
      HomuGetter::get_res headNo
    end

    private

    def view_erb tag, opt = {}
      css_list = ["#{tag}.css"] if opt[:css].nil?
      count = request.env['WsClientCount']
      bg = Dir.glob('./public/bgs/*.png').map { |i| File.basename i }.sample
      locals = { css_list: css_list, ws_client_count: count, bg: bg }
      locals.merge!(opt[:locals]) unless opt[:locals].nil?
      erb(tag, locals: locals)
    end

    run! if app_file == $PROGRAM_NAME
  end
end
