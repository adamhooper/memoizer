module Memoizer
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods) # For instance-method memoizing
    base.extend(InstanceMethods) # For class-method memoizing
  end

  module ClassMethods
    def memoize(method_name, scope = nil)
      if method_defined?(method_name)
        # Instance-method memoizing
        define_memoize_method(self, method_name, scope)
        alias_method_chain method_name, :memoize
      else
        # Class-method memoizing
        base = self
        (class << self; self; end).instance_eval do
          base.send(:define_memoize_method, self, method_name, scope)
          alias_method_chain method_name, :memoize
        end
      end
    end

    def memoize_globally(method)
      # Both instance-level and class-level
      memoize(method, :global)
    end

    private

    def define_memoize_method(parent, method_name, scope)
      parent.send(:define_method, "#{method_name}_with_memoize") do |*args|
        scope ||= self
        key = [scope, method_name] + args
        cache = memoize_cache

        if cache && cache.has_key?(key)
          return cache.get(key)
        end

        result = send("#{method_name}_without_memoize", *args)
        if cache
          cache.put(key, result)
        end

        result
      end
    end
  end

  module InstanceMethods
    private

    def memoize_cache
      if memoize_enabled && memoize_piggyback_object
        memoize_piggyback_object[:memoize] ||= MemoizeCache.new
      else
        nil
      end
    end

    def memoize_enabled
      memoize_connection.query_cache_enabled
    end

    def memoize_piggyback_object
      memoize_connection.instance_variable_get(:@query_cache)
    end

    def memoize_connection
      if respond_to?(:connection)
        connection
      else
        ActiveRecord::Base.connection
      end
    end
  end

  class MemoizeCache
    def initialize
      @data = {}
    end

    def has_key?(key)
      @data.has_key?(key)
    end

    def get(key)
      @data[key]
    end

    def put(key, value)
      @data[key] = value
    end
  end
end
