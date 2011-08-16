require 'helper'

class TestTestSeeds < ActiveSupport::TestCase
  include TestSeeds

  fixtures :authors

  seeds do
    @default_1 = Author.create!(:name => 'default first')
    @default_2 = Author.create!(:name => 'default second')
  end

  seeds(:foo) do
    @foo_1 = Author.create!(:name => 'foo first')
    @foo_2 = Author.create!(:name => 'foo second')
  end

  def test_default_seeds
    assert_not_nil @default_1
    assert_equal "default first", @default_1.name
    
    assert_not_nil @default_2
    assert_equal "default second", @default_2.name
    
    assert_nil @foo_1
    assert_nil @foo_2
  end

  def test_setup_and_teardown
    assert_not_nil @default_1
    assert_not_nil @default_2

    setup_seeds(:foo)

    assert_not_nil @default_1
    assert_not_nil @default_2

    assert_not_nil @foo_1
    assert_equal "foo first", @foo_1.name
    
    assert_not_nil @foo_2
    assert_equal "foo second", @foo_2.name
    
    teardown_seeds(:foo)

    assert_nil @foo_1
    assert_nil @foo_2
    assert_not_nil @default_1
    assert_not_nil @default_2
  end
  
  def test_set_seed_fixture
    author = Author.create!(:name => 'tolkien')
    assert_equal ["authors", :tolkien], set_seed_fixture("tolkien", author)
    assert_equal author, authors(:tolkien)
  end

  def test_set_seed_fixture__expects_active_record
    assert_raises(RuntimeError) do
      set_seed_fixture("hmm", Object.new)
    end
  end

  def test_does_not_interfere_with_actual_fixtures
    assert_not_nil authors(:actual_fixture)
    assert_equal "Bob Dole", authors(:actual_fixture).name
  end
  
end

class TestTestSeedsWithoutSeedSet < ActiveSupport::TestCase
  include TestSeeds
  
  def test_does_not_blow_up_when_test_seeds_is_not_used
    assert true
  end
end