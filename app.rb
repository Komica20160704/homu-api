# encoding: utf-8
require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/reloader'
require 'sinatra/json'
require 'date'
require 'digest'
require 'rest-client'
require 'json'
require 'jwt'
require './lib/homu_getter'
require './lib/view_helpers'

module HomuApi
  class App < Sinatra::Base
    helpers Sinatra::Cookies
    helpers ViewHelpers

    configure :development do
      register Sinatra::Reloader
    end

    get '/css/:style.css' do |style|
      content_type :'text/css'
      erb :"css/#{style}.css", layout: '<%= yield %>'
    end

    THEMES = %i[tawawa dark hatobatsugu].map(&:freeze).freeze

    THEMES.each do |theme|
      get "/#{theme}" do
        if cookies[theme] && !params[:force]
          cookies.delete theme
        else
          THEMES.each { |theme| cookies.delete theme }
          cookies[theme] = 1
        end
        redirect back
      end
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
      view_erb(:follow, locals: { resNo: resNo, token: token })
    end

    get /\/(?<headNo>[0-9]+)/ do |headNo|
      return 403 if params[:token] != token
      content_type :json, charset: 'utf-8'
      HomuGetter::get_res headNo
    end

    private

    DEFAULT_JS_LIST = %w[tawawa.js].map(&:freeze).freeze
    DEFAULT_CSS_LIST = %w[layout.css main.css television.css].map(&:freeze).freeze

    def view_erb tag, opt = {}
      css_list = DEFAULT_CSS_LIST.dup
      css_list.push("#{tag}.css")
      css_list.push("#{curren_theme}.css") if curren_theme
      js_list = DEFAULT_JS_LIST
      count = request.env['WsClientCount']
      bg = pick_background_img css_list
      locals = { css_list: css_list, js_list: js_list, ws_client_count: count, bg: bg }
      locals.merge!(opt[:locals]) unless opt[:locals].nil?
      erb(tag, locals: locals)
    end

    def pick_background_img css_list
      bg_dir = './public/bgs/*.png'
      if Time.now.monday? && curren_theme.nil?
        css_list.push 'tawawa.css'
        bg_dir = './public/bgs/tawawa/*.png'
      elsif curren_theme
        bg_dir = "./public/bgs/#{curren_theme}/*.png"
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

    def curren_theme
      @curren_theme ||= THEMES.find { |theme| !!cookies[theme] }
    end

    run! if app_file == $PROGRAM_NAME
  end
end
