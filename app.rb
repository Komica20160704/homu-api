# encoding: utf-8
require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/reloader'
require 'sinatra/json'
require './helper/homu_getter'
require 'date'
require 'digest'
require 'rest-client'
require 'json'
require 'jwt'

module HomuApi
  class App < Sinatra::Base
    helpers Sinatra::Cookies

    configure :development do
      register Sinatra::Reloader
    end

    get '/css/:style.css' do |style|
      content_type :'text/css'
      erb :"css/#{style}.css", layout: '<%= yield %>'
    end

    get '/2018bomb' do
      is_pass = $homu_redis.get('2018bomb') == 'pass'
      messages = $homu_redis.smembers('2018bomb_messages')
      puts messages.to_json
      view_erb :'2018bomb', locals: { is_pass: is_pass, token: ENV['BOMB_TOKEN'], messages: messages }
    end

    post '/2018bomb' do
      secret = params[:secret]
      token = ENV['BOMB_TOKEN']
      begin
        decoded_token = JWT.decode token, secret, true, { algorithm: 'HS256' }
        $homu_redis.set '2018bomb', 'pass'
        json success: true
      rescue JWT::DecodeError
        json success: false, message: '密碼是錯的，不要亂來好嗎？'
      end
    end

    post '/2018bomb/messages' do
      secret = ENV['2018BOMB']
      token = params[:token]
      if Time.now < Time.new('2018/1/1')
        begin
          decoded_token = JWT.decode token, secret, true, { algorithm: 'HS256' }
        rescue JWT::DecodeError
          json success: false, message: '密碼是錯的，不要亂來好嗎？'
        end
      else
        decoded_token = JWT.decode token, nil, false
      end
      payload = decoded_token.first
      message = "[#{Time.now.strftime('%Y/%m/%d %H:%M:%S')}] #{payload['name']}: #{payload['message']}"
      $homu_redis.sadd '2018bomb_messages', message
      json success: true, message: message
    end

    get '/dark' do
      if cookies[:dark]
        cookies.delete :dark
      else
        cookies[:dark] = 1
      end
      redirect back
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
      css_list = ["main.css", "#{tag}.css", "television.css", "id-hider.css"]
      css_list = css_list.concat(opt[:css].to_a)
      js_list = ["tawawa.js"]
      count = request.env['WsClientCount']
      bg = pick_background_img opt[:tawawa], css_list
      locals = { css_list: css_list, js_list: js_list, ws_client_count: count, bg: bg }
      locals.merge!(opt[:locals]) unless opt[:locals].nil?
      erb(tag, locals: locals)
    end

    def pick_background_img is_tawawa, css_list
      bg_dir = './public/bgs/*.png'
      if Time.now.monday? || is_tawawa
        css_list.push('tawawa.css')
        bg_dir = './public/bgs/tawawa/*.png'
      elsif cookies[:dark]
        css_list.push('dark.css')
      elsif Random.rand * 256 > 255
        bg_dir = './public/bgs/koiking/*.png'
      end
      Dir.glob(bg_dir).map { |i| i.sub!('./public', '') }.sample
    end

    def token
      md5 = Digest::MD5.new
      secret = ENV['SECRET'].to_s
      today = Time.now.strftime '%Y/%m/%d'
      ip = request.ip.to_s
      md5 << secret << today << ip
      md5.hexdigest[9..16]
    end

    run! if app_file == $PROGRAM_NAME
  end
end
