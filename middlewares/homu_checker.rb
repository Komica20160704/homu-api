require 'rufus-scheduler'
require 'open-uri'
require 'json'

module HomuApi
  class HomuChecker
    def initialize web_socket
      @web_socket = web_socket
      @url = 'http://homu-homuapi.rhcloud.com/'
      @scheduler = Rufus::Scheduler.new
      @blocks = Hash.new false
      check get_data
      @scheduler.every '10s' do check_news end
    end

    def call env
      @web_socket.call env
    end

    private

    def check_news
      data = get_data
      news = check data
      notify news if news.size > 0
    end

    def notify data
      @web_socket.notify data.to_json
    end

    def get_data
      data = JSON.parse(open(@url + '/page/0').read)
      data = reform_data data
    end

    def check data
      news = []
      data.each do |block|
        if @blocks[block['No']] == false
         @blocks[block['No']] = true
         news << block
        end
      end
      return news
    end

    def reform_data data
      new_data = []
      data.each do |dialog|
        head_no = dialog['Head']['No']
        if dialog['Head']['Hidenbodycount']
          dialog['Head']['Count'] = dialog['Head']['Hidenbodycount']
          dialog['Head'].delete 'Hidenbodycount'
        end
        new_dialog = [dialog['Head']] + dialog['Bodies']
        new_dialog.each do |block|
          block['HeadNo'] = head_no
        end
        new_data += new_dialog
      end
      return new_data
    end
  end
end
