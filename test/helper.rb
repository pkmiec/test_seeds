require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

require 'active_support'
require 'active_record'
require 'active_record/fixtures'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'test_seeds'

ActiveRecord::Base.logger = Logger.new("debug.log")

# Re-create test database
`mysql -uroot -e "DROP DATABASE IF EXISTS test_test_seeds; CREATE DATABASE IF NOT EXISTS test_test_seeds;"`

# Define connection configuration
ActiveRecord::Base.configurations = {
  'test_test_seeds' => {
    :adapter  => 'mysql2',
    :username => 'root',
    :encoding => 'utf8',
    :database => 'test_test_seeds',
  }
}
ActiveRecord::Base.establish_connection 'test_test_seeds'

# Define schema
ActiveRecord::Schema.define do
  
  create_table :authors, :force => true do |t|
    t.string :name
  end
  
end

class Author < ActiveRecord::Base
end

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
end

ActiveSupport::TestCase.fixture_path = File.join(File.dirname(__FILE__), 'fixtures')
