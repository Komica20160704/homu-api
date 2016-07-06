require 'rufus-scheduler'
require 'open-uri'
require 'json'
require 'date'

module HomuApi
  class HomuChecker
    def initialize notifier
      @notifier = notifier
      @url = 'http://homu-homuapi.rhcloud.com/'
      @scheduler = Rufus::Scheduler.new
      @blocks = Hash.new false
      @last_check_time = DateTime.new
      check get_data
      @last_check_time = DateTime.now
      @scheduler.every '10s' do check_news end
    end

    def call env
      @notifier.call env
    end

    private

    def check_news
      begin
        data = get_data
        new_data = check data
        notify new_data
        @last_check_time = DateTime.now
      rescue Exception => e
        puts e.message
      end
    end

    def notify data
      if data['Blocks'].size > 0
        data['Type'] = 'Notify'
        @notifier.notify data
      end
    end

    def get_data
      data = JSON.parse(open(@url + '/page/0').read)
      data = reform_data data
    end

    def check data
      new_data = { "Heads" => [], "Blocks" => [] }
      data['Blocks'].each do |block|
        check_block block, new_data, data['HeadHash']
      end
      new_data['Heads'].uniq!
      new_data['Blocks'].sort! { |a, b| a['No'] <=> b['No'] }
      return new_data
    end

    def check_block block, new_data, head_hash
      if @blocks[block['No']] == false
        @blocks[block['No']] = true
        block_time = get_block_time block
        if block_time > @last_check_time
          new_data['Heads'] << head_hash[block['HeadNo']]
          new_data['Blocks'] << block
        end
      end
    end

    def get_block_time block
      time_string = block['Date'] + ' ' + block['Time'] + '+8'
      DateTime.parse time_string
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
