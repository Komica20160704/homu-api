# encoding: utf-8
require 'sinatra/base'
require "sinatra/reloader"
require './helper/homu_getter'
require 'date'

module HomuApi
  class App < Sinatra::Base
    configure :development do
      register Sinatra::Reloader
    end

    get '/kumiko' do
      erb :kumiko, layout: '<%= yield %>'
    end

    get '/report' do
      view_erb :report
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
      css_list = ["#{tag}.css", "television.css"]
      css_list = css_list.concat(opt[:css].to_a)
      if Time.now.monday?
        css_list.push("tawawa.css")
        bg_dir = './public/bgs/tawawa/*.png'
      else
        bg_dir = './public/bgs/*.png'
      end
      count = request.env['WsClientCount']
      bg = Dir.glob(bg_dir).map { |i| i.sub!('./public', '') }.sample
      locals = { css_list: css_list, ws_client_count: count, bg: bg }
      locals.merge!(opt[:locals]) unless opt[:locals].nil?
      erb(tag, locals: locals)
    end

    run! if app_file == $PROGRAM_NAME
  end
end
