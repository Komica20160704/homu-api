# frozen_string_literal: true

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
require './lib/app_helpers'
require './lib/view_helpers'

module HomuApi
  class App < Sinatra::Base
    set :env, ENV['RACK_ENV']
    helpers Sinatra::Cookies
    helpers AppHelpers
    helpers ViewHelpers

    configure :development do
      register Sinatra::Reloader
    end

    before do
      uri = URI homu_url
      if request.host != uri.host
        redirect to(uri.host), 301
      end
    end

    get '/css/:style.css' do |style|
      content_type :'text/css'
      erb :"css/#{style}.css", layout: '<%= yield %>'
    end

    THEMES.each do |theme|
      get "/#{theme}" do
        if cookies[theme] && !params[:force]
          cookies.delete theme
        else
          THEMES.each { |t| cookies.delete t }
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

    get '/search' do
      view_erb :search
    end

    get '/' do
      view_erb :index
    end

    get '/follow/:res_no' do |res_no|
      view_erb(:follow, locals: { resNo: res_no, token: token })
    end

    get %r{/(?<head_no>[0-9]+)} do |head_no|
      return 403 if params[:token] != token
      content_type :json, charset: 'utf-8'
      HomuGetter.get_res head_no
    end
  end
end
