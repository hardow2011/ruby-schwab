require 'csv'
require 'pry'
require 'date'
require 'forwardable'

class Schwab

  class Transaction; end
  class TransactionsArray < Array; end

  module Plugins
    module Core
      module SchwabMethods
        extend Forwardable

        attr_reader :transactions
        def_delegators :transactions, :sort_attribute_by, :filter_transactions_by_dates

        def initialize(csv_file_name)
          return if csv_file_name.nil?
          csv = CSV.read(csv_file_name)
          transactions_first_index = nil
          csv.each_with_index do |row, i|
            transactions_first_index = i+1 if row[0] == "Posted Transactions"
          end
          csv[transactions_first_index..-1].each_with_index do |row, i|
            date = Date.strptime(row[0], "%m/%d/%Y")
            type = convert_to_symbol(row[1])
            description = row[3]
            withdrawal = convert_to_float(row[4])
            deposit = convert_to_float(row[5])
            running_balance = convert_to_float(row[6])
            # Swap the order of the transactions
            (@transactions ||= TransactionsArray.new).prepend Transaction.new(date, type, description, withdrawal, deposit, running_balance)
          end
        end

        private

        def convert_to_float(string)
          string.gsub(/[^(\d|\.)]/, "").to_f
        end

        def convert_to_symbol(type)
          type.downcase.gsub(/\s+/, "").to_sym
        end

      end
      module TransactionMethods
        attr_reader :date, :type, :description, :withdrawal, :deposit, :running_balance
        def initialize(date, type, description, withdrawal, deposit, running_balance)
          @date = date
          @type = type
          @description = description
          @withdrawal = withdrawal
          @deposit = deposit
          @running_balance = running_balance
        end
      end
      module TransactionsArrayMethods
        # ex: sort_attribute_by(:withdrawal, :description)
        # ex: sort_attribute_by(:deposit, :type, true)
        def sort_attribute_by(attribute, grouping, ascending=nil)
          result = self.group_by { |t| t.send(grouping) } # group values by grouping argument
            # transform the values of each grouping to the sum of its transactions
            .transform_values { |t| t.map{ |t| t.send(attribute) }.sum.round(2) }
            # remove transactions that are zero
            .select { |k,v| v > 0 }
            # sort by descending
            .sort_by { |t, v| -v }
          return result.reverse.to_h if ascending == true
          result.to_h
        end

        def filter_transactions_by_dates(start, finish=nil)
          finish = Date.today if finish.nil?
          TransactionsArray.new self.filter { |t| t.date.between?(start, finish) }
        end
      end
    end
  end

  def self.plugin(mod)
    if defined?(mod::SchwabMethods)
      include(mod::SchwabMethods)
    end
    if defined?(mod::TransactionMethods)
      Transaction.include(mod::TransactionMethods)
    end
    if defined?(mod::TransactionsArrayMethods)
      TransactionsArray.include(mod::TransactionsArrayMethods)
    end
  end

  plugin(Plugins::Core)

end

=begin
examples:
b = Schwab.new("XXXXXXXXX.csv")
b.sort_attribute_by(:deposit, :type, true)
b.sort_attribute_by(:withdrawal, :description)
b.filter_transactions_by_dates(Date.new(2023, 11, 1))
b.filter_transactions_by_dates(Date.new(2023, 11, 1)).sort_attribute_by(:withdrawal, :
description)
=end
