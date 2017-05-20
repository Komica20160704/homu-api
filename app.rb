# encoding: utf-8
require 'sinatra/base'
require "sinatra/reloader"
require './helper/homu_getter'
require 'date'
require 'digest'

module HomuApi
  class App < Sinatra::Base
    configure :development do
      register Sinatra::Reloader
    end

    get '/css/tawawa.css' do
      content_type :'text/css'
      erb :'css/tawawa.css', layout: '<%= yield %>'
    end

    get '/kumiko' do
      erb :kumiko, layout: '<%= yield %>'
    end

    get '/tawawa' do
      view_erb :index, tawawa: true
    end

    get '/report' do
      view_erb :report
    end

    get '/' do
      view_erb :index
    end

    get '/follow/:resNo' do |resNo|
      view_erb(:follow, locals: { resNo: resNo, token: token })
    end

    get /\/(?<headNo>[0-9]+)/ do |headNo|
      return 403 if params[:token] != token
      content_type :json, :charset => 'utf-8'
      HomuGetter::get_res headNo
    end

    private

    def view_erb tag, opt = {}
      css_list = ["#{tag}.css", "television.css", "id-hider.css"]
      css_list = css_list.concat(opt[:css].to_a)
      js_list = ["tawawa.js"]
      if Time.now.monday? || opt[:tawawa]
        css_list.push("tawawa.css")
        bg_dir = './public/bgs/tawawa/*.png'
      else
        bg_dir = './public/bgs/*.png'
      end
      count = request.env['WsClientCount']
      bg = Dir.glob(bg_dir).map { |i| i.sub!('./public', '') }.sample
      locals = { css_list: css_list, js_list: js_list, ws_client_count: count, bg: bg }
      locals.merge!(opt[:locals]) unless opt[:locals].nil?
      erb(tag, locals: locals)
    end

    def token
      md5 = Digest::MD5.new
      secret = ENV['SECRET'].to_s
      today = Time.now.strftime("%Y/%m/%d")
      ip = request.ip.to_s
      md5 << secret << today << ip
      md5.hexdigest[9..16]
    end

    run! if app_file == $PROGRAM_NAME
  end
end
