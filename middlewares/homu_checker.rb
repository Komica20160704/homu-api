# frozen_string_literal: true

require 'rufus-scheduler'
require 'date'
require './lib/homu_getter'
require './lib/data_reformater'

module HomuApi
  class HomuChecker
    REFRESH_TIME = ENV['REFRESH_TIME'] || 30

    def initialize(notifier)
      @notifier = notifier
      @scheduler = Rufus::Scheduler.new
      @blocks = Hash.new false
      @last_block_no = ''
      check query_data
      @scheduler.every("#{REFRESH_TIME}s") { check_news }
    end

    def call(env)
      @notifier.call env
    end

    private

    def check_news
      data = query_data
      new_data = check data
      notify new_data
    rescue StandardError => e
      puts e.message
    end

    def notify(data)
      return if data['Blocks'].empty?
      data['Type'] = 'Notify'
      @notifier.notify data
    end

    def query_data
      data = JSON.parse(HomuGetter.get_page)
      reform_data data
    end

    def check(data)
      new_data = { 'Heads' => [], 'Blocks' => [] }
      data['Blocks'].each do |block|
        check_block block, new_data, data['HeadHash']
      end
      new_data['Heads'].uniq!
      new_data
    end

    def check_block(block, new_data, head_hash)
      return if block['No'] <= @last_block_no
      @last_block_no = block['No']
      new_data['Heads'] << head_hash[block['HeadNo']]
      new_data['Blocks'] << block
    end

    def reform_data(data)
      reformater = DataReformater.new(data)
      reformater.perform
    end
  end
end
