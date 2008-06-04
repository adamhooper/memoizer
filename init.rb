require 'memoizer'
ActiveRecord::Base.send(:include, Memoizer)
