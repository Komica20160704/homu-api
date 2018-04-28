# encoding: utf-8
require 'open-uri'
require 'json'

module HomuApi
  module HomuGetter
    @url = 'http://homu.homu-api.com/' if ENV['RACK_ENV'] == 'production'
    @url = 'http://api-homu.dev/' if ENV['RACK_ENV'] == 'development'

    def self.get_page page = '0'
      begin
        return open(@url + '/page/' + page).read
      rescue OpenURI::HTTPError => e
        puts 'OpenURI::HTTPError'
        puts e.message
        puts e.backtrace
        return '{}'
      end
    end

    def self.get_res res
      begin
        return open(@url + '/res/' + res).read
      rescue OpenURI::HTTPError => e
        puts 'OpenURI::HTTPError'
        puts e.message
        puts e.backtrace
        return '{}'
      end
    end
  end
end