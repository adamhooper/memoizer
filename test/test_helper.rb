$:.unshift(File.dirname(__FILE__) + '/../lib')
RAILS_ROOT = File.dirname(__FILE__)

require 'rubygems'

require 'active_record'
require 'active_record/connection_adapters/abstract_adapter'
require "#{File.dirname(__FILE__)}/../init"

module ActiveRecord
  class Base
    # We call the adapter "abstract" because otherwise we need a gem
    def self.abstract_connection(config)
      ActiveRecord::ConnectionAdapters::AbstractAdapter.new(nil, logger)
    end
  end

  module ConnectionAdapters
    class AbstractAdapter
      def columns(table_name, name = nil)
        []
      end
    end
  end
end

config = { 'test' => { 'adapter' => 'abstract' } }
ActiveRecord::Base.configurations = config
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])

require 'test/unit'
