# encoding: utf-8
require 'open-uri'
require 'json'

module HomuApi
  module HomuGetter
    @url = 'http://homu-homuapi.rhcloud.com/'

    def self.get_page page = '0'
      open(@url + '/page/' + page).read
    end

    def self.get_res res
      open(@url + '/res/' + res).read
    end
  end
end
