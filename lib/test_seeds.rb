require 'active_support'
require 'active_record'
require 'active_record/fixtures'

module TestSeeds
      
  class SeedFixture < ActiveRecord.const_defined?(:Fixture) ? ActiveRecord::Fixture : Fixture

    # Override find to call find with exclusive scope. Shouldn't fixtures do that already?
    def find
      if model_class
        model_class.send(:with_exclusive_scope) do
          model_class.find(@fixture[model_class.primary_key])
        end
      else
        raise FixtureClassNotFound, "No class attached to find."
      end
    end
    
  end
  
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks
    define_callbacks :seed
  end

  module ClassMethods
    def seeds(name = nil, &block)
      set_callback(:seed, :before) do
        pre_vars = self.instance_variables
        self.instance_eval &block
        post_vars = self.instance_variables

        (post_vars - pre_vars).each do |seed_var|
          seed_name = seed_var.to_s[1..-1]
          next if seed_name.starts_with?("_")
          
          seed_accessor = self.set_seed_fixture(seed_name, self.instance_variable_get(seed_var))
          self.instance_variable_set(seed_var, nil) # avoid memory bloat

          defined_seeds = self.class.defined_seeds
          defined_seeds[name] ||= {}
          defined_seeds[name][seed_var] = seed_accessor
        end
        
      end
    end

    def defined_seeds
      @defined_seeds ||= {}
    end
    
  end

  # Re-implement setup_fixtures to use save points instead of transactions.
  def setup_fixtures
    return unless defined?(ActiveRecord) && !ActiveRecord::Base.configurations.blank?

    if pre_loaded_fixtures && !use_transactional_fixtures
      raise RuntimeError, 'pre_loaded_fixtures requires use_transactional_fixtures'
    end

    @fixture_cache = {}
    @@already_loaded_fixtures ||= {}

    @loaded_seeds = []

    if run_in_transaction?
      if @@already_loaded_fixtures[self.class]
        @loaded_fixtures = @@already_loaded_fixtures[self.class]
      else
        @loaded_fixtures = load_fixtures
        @@already_loaded_fixtures[self.class] = @loaded_fixtures
      end

      # Use safe points
      ActiveRecord::Base.connection.create_savepoint
      ActiveRecord::Base.connection.increment_open_transactions
      ActiveRecord::Base.connection.transaction_joinable = false
      @created_save_point = true
      
      setup_seeds(nil)
    else
      Fixtures.reset_cache
      @@already_loaded_fixtures[self.class] = nil
      @loaded_fixtures = load_fixtures
    end

    instantiate_fixtures if use_instantiated_fixtures
  end

  # Re-implement setup_fixtures to use save points instead of transactions.
  def teardown_fixtures
    teardown_seeds(*@loaded_seeds)
    
    return unless defined?(ActiveRecord) && !ActiveRecord::Base.configurations.blank?

    unless run_in_transaction?
      Fixtures.reset_cache
    end

    if run_in_transaction? && @created_save_point
      # Use safe points
      ActiveRecord::Base.connection.decrement_open_transactions
      ActiveRecord::Base.connection.rollback_to_savepoint
      @created_save_point = false
    end
    ActiveRecord::Base.clear_active_connections!
  end

  # Load fixture is called once for each test class which is a good place to inject db transactions
  # and to create the seeds.
  def load_fixtures
    if run_in_transaction? && ActiveRecord::Base.connection.open_transactions != 0
      ActiveRecord::Base.connection.decrement_open_transactions
      ActiveRecord::Base.connection.rollback_db_transaction
    end
    ActiveRecord::Base.clear_active_connections!

    # In Rails 3.0.x, load_fixtures sets the @loades_fixtures instance variable. In Rails 3.1, load_fixtures returns the 
    # fixtures which are then assigned to @loaded_fixtures by the caller. The following line ensures compability with
    # Rails 3.1. 
    result = super
    @loaded_fixtures = result if result.is_a? Hash

    if run_in_transaction?
      ActiveRecord::Base.connection.begin_db_transaction
      ActiveRecord::Base.connection.increment_open_transactions
      ActiveRecord::Base.connection.transaction_joinable = false
    end
    
    load_seed_fixtures
    
    @loaded_fixtures
  end

  def setup_seeds(*seeds)
    seeds.each do |seed|
      (self.class.defined_seeds[seed] || []).each do |seed_var, seed_accessor|
        instance_variable_set(seed_var, send(*seed_accessor))
      end
      @loaded_seeds << seed
    end
  end

  def teardown_seeds(*seeds)
    seeds.each do |seed|
      (self.class.defined_seeds[seed] || []).each do |seed_var, seed_accessor|
        instance_variable_set(seed_var, nil)
      end
      @loaded_seeds.delete(seed)
    end
  end

  def set_seed_fixture(seed_name, seed_model)
    raise "Seed fixture must be an instance of ActiveRecord::Base" unless seed_model.is_a? ActiveRecord::Base
    
    seed_class = seed_model.class
    fixture = { seed_class.primary_key => seed_model.send(seed_class.primary_key) }
    @loaded_fixtures[seed_class.table_name][seed_name.to_s] = SeedFixture.new(fixture, seed_class)
    
    [ seed_class.table_name, seed_name.to_sym ]
  end
  
  def load_seed_fixtures
    ActiveRecord::Base.connection.transaction(:requires_new => true) do
      _run_seed_callbacks
    end
  end
end
