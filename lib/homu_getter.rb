# frozen_string_literal: true

require 'json'

module HomuApi
  module HomuGetter
    @url = 'http://homu.homu-api.com/' if ENV['RACK_ENV'] == 'production'
    @url = 'http://api-homu.dev/' if ENV['RACK_ENV'] == 'development'

    def self.get_page(page = '0')
      uri = URI("#{@url}page/#{page}")
      Net::HTTP.get(uri)
    rescue StandardError => e
      puts '[ERROR] HomuApi::HomuGetter.get_page'
      puts e.message
      puts e.backtrace
      '{}'
    end

    def self.get_res(res)
      uri = URI("#{@url}res/#{res}")
      Net::HTTP.get(uri)
    rescue StandardError => e
      puts '[ERROR] HomuApi::HomuGetter.get_res'
      puts e.message
      puts e.backtrace
      '{}'
    end
  end
end
