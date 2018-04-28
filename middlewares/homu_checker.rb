require 'rufus-scheduler'
require 'date'
require './lib/homu_getter'

module HomuApi
  class HomuChecker
    REFRESH_TIME = ENV['REFRESH_TIME'] || 30

    def initialize notifier
      @notifier = notifier
      @scheduler = Rufus::Scheduler.new
      @blocks = Hash.new false
      @last_block_no = ""
      check get_data
      @scheduler.every "#{REFRESH_TIME}s" do check_news end
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
      data = JSON.parse(HomuGetter::get_page)
      data = reform_data data
    end

    def check data
      new_data = { "Heads" => [], "Blocks" => [] }
      data['Blocks'].each do |block|
        check_block block, new_data, data['HeadHash']
      end
      new_data['Heads'].uniq!
      return new_data
    end

    def check_block block, new_data, head_hash
      if block['No'] > @last_block_no
        @last_block_no = block['No']
        new_data['Heads'] << head_hash[block['HeadNo']]
        new_data['Blocks'] << block
      end
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
      blocks.sort! { |a, b| a['No'] <=> b['No'] }
      return { "HeadHash" => head_hash, "Blocks" => blocks }
    end
  end
end
