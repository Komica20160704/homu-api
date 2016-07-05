require 'rufus-scheduler'
require 'open-uri'
require 'json'
require 'date'

module HomuApi
  class HomuChecker
    def initialize web_socket
      @web_socket = web_socket
      @url = 'http://homu-homuapi.rhcloud.com/'
      @scheduler = Rufus::Scheduler.new
      @blocks = Hash.new false
      @last_check_time = DateTime.new
      check get_data
      @last_check_time = DateTime.now
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
      @last_check_time = DateTime.now
    end

    def notify data
      @web_socket.notify data.to_json
    end

    def get_data
      data = JSON.parse(open(@url + '/page/0').read)
      data = reform_data data
    end

    def check data
      new_heads = []
      news = []
      data['Blocks'].each do |block|
        if @blocks[block['No']] == false
          @blocks[block['No']] = true
          block_time = get_block_time block
          if block_time > @last_check_time
            new_heads << data['HeadHash'][block['HeadNo']]
            news << block
          end
        end
      end
      news.sort! { |a, b| a['No'] <=> b['No'] }
      return { "Heads" => new_heads, "Blocks" => news }
    end

    def get_block_time block
      DateTime.parse(block['Date'] + ' ' + block['Time'] + '+8')
    end

    def reform_data data
      head_hash = {}
      blocks = []
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
        head_hash[head_no] = dialog['Head']
        blocks += new_dialog
      end
      return { "HeadHash" => head_hash, "Blocks" => blocks }
    end
  end
end
