# frozen_string_literal: true

class DataReformater
  def initialize(data)
    @head_hash = {}
    @blocks = []
    @data = data
  end

  def perform
    perform_data
    @blocks.sort! { |a, b| a['No'] <=> b['No'] }
    { 'HeadHash' => @head_hash, 'Blocks' => @blocks }
  end

  private

  def perform_data
    @data.each do |dialog|
      head_no = dialog['Head']['No']
      if dialog['Head']['Hidenbodycount']
        dialog['Head']['Count'] = dialog['Head'].delete 'Hidenbodycount'
      end
      new_dialog = [dialog['Head']] + dialog['Bodies']
      new_dialog.each { |block| block['HeadNo'] = head_no }
      @head_hash[head_no] = dialog['Head']
      @blocks += new_dialog
    end
  end
end
