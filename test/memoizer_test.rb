require File.dirname(__FILE__) + '/test_helper'

class MemoizerTest < Test::Unit::TestCase
  class MockRecord < ActiveRecord::Base
    # Returns the number of times long_running_method has been called
    def long_running_method
      @i ||= 0
      return @i += 1
    end
  end

  class MockRecord2 < ActiveRecord::Base
    # Same method name, in case of conflicts
    def long_running_method
      @i ||= 10
      return @i += 1
    end
  end

  class MockRecordNonActiveRecord
    include Memoizer
    def long_running_method
      @i ||= 0
      return @i += 1
    end
    memoize :long_running_method
  end

  class MockRecordWithMemoize < MockRecord
    include Memoizer
    memoize :long_running_method
  end

  class MockRecord2WithMemoize < MockRecord2
    include Memoizer
    memoize :long_running_method
  end

  class MockRecordWithMemoizedStaticMethod < ActiveRecord::Base
    include Memoizer
    def self.long_running_method
      @i ||= 0
      return @i += 1
    end
    memoize :long_running_method
  end

  class MockRecordWithGlobalMemoize < MockRecord
    include Memoizer
    memoize_globally :long_running_method
  end

  class MockRecord2WithGlobalMemoize < MockRecord2
    include Memoizer
    memoize_globally :long_running_method
  end

  class MockRecordChildWithMemoize < MockRecordWithMemoize
  end

  class MockRecordWithScopedMemoize < MockRecord
    include Memoizer
    def long_running_method
      @i ||= 10
      return @i += 1
    end
    memoize :long_running_method, '1'
  end

  class MockRecordWithScopedMemoize2 < MockRecord
    include Memoizer
    def long_running_method
      @i ||= 20
      return @i += 1
    end
    memoize :long_running_method, '2'
  end

  class MockRecordWithSameScopedMemoize < MockRecord
    include Memoizer
    def long_running_method
      @i ||= 30
      return @i += 1
    end
    memoize :long_running_method, '1'
  end

  class MockRecordChildWithMemoizeAndMethod < MockRecordWithMemoize
    def long_running_method
      @i ||= 20
      return @i += 1
    end
  end

  def test_returns_proper_value_without_cache
    m = MockRecordWithMemoize.new
    assert_equal 1, m.long_running_method
    assert_equal 2, m.long_running_method
  end

  def test_returns_cached_value_with_cache
    m = MockRecordWithMemoize.new
    ActiveRecord::Base.connection.cache do
      assert_equal 1, m.long_running_method
      assert_equal 1, m.long_running_method
    end
  end

  def test_works_with_static_method
    ActiveRecord::Base.connection.cache do
      assert_equal 1, MockRecordWithMemoizedStaticMethod.long_running_method
      assert_equal 1, MockRecordWithMemoizedStaticMethod.long_running_method
    end
  end

  def test_ignores_cached_value_when_uncached
    m = MockRecordWithMemoize.new
    ActiveRecord::Base.connection.cache do
      assert_equal 1, m.long_running_method
      m.connection.uncached do
        assert_equal 2, m.long_running_method
        assert_equal 3, m.long_running_method
      end
      assert_equal 1, m.long_running_method
    end
  end

  def test_uncaches_when_needed
    m = MockRecordWithMemoize.new
    ActiveRecord::Base.connection.cache do
      assert_equal 1, m.long_running_method
      assert_equal 1, m.long_running_method
    end
    assert_equal 2, m.long_running_method
  end

  def test_dirties_when_needed
    m = MockRecordWithMemoize.new
    ActiveRecord::Base.connection.cache do
      assert_equal 1, m.long_running_method
      m.connection.clear_query_cache
      assert_equal 2, m.long_running_method
    end
  end

  def test_caches_per_class
    m1 = MockRecordWithMemoize.new
    m2 = MockRecord2WithMemoize.new
    ActiveRecord::Base.connection.cache do
      assert_equal 1, m1.long_running_method
      assert_equal 11, m2.long_running_method
      assert_equal 1, m1.long_running_method
      assert_equal 11, m2.long_running_method
    end
  end

  def test_caches_globally
    m1 = MockRecordWithGlobalMemoize.new
    m2 = MockRecord2WithGlobalMemoize.new
    ActiveRecord::Base.connection.cache do
      assert_equal 1, m1.long_running_method
      assert_equal 1, m2.long_running_method
    end
  end

  def test_children_follow_memoize
    m1 = MockRecordWithMemoize.new
    m2 = MockRecordChildWithMemoize.new

    ActiveRecord::Base.connection.cache do
      assert_equal 1, m1.long_running_method
      assert_equal 1, m2.long_running_method
    end
  end

  def test_children_with_new_method_avoid_memoize
    m = MockRecordChildWithMemoizeAndMethod.new
    ActiveRecord::Base.connection.cache do
      assert_equal 21, m.long_running_method
      assert_equal 22, m.long_running_method
    end
  end

  def test_scoped
    m1 = MockRecordWithScopedMemoize.new
    m2 = MockRecordWithScopedMemoize2.new
    m3 = MockRecordWithSameScopedMemoize.new
    ActiveRecord::Base.connection.cache do
      assert_equal 11, m1.long_running_method
      assert_equal 21, m2.long_running_method
      assert_equal 11, m3.long_running_method
    end
  end

  def test_non_active_record
    m = MockRecordNonActiveRecord.new
    ActiveRecord::Base.connection.cache do
      assert_equal 1, m.long_running_method
      assert_equal 1, m.long_running_method
    end
  end
end
