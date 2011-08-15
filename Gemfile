source "http://rubygems.org"

group :development do
  gem "jeweler", "~> 1.6.4"
  gem "rake"

  gem 'mysql2', '< 0.3'

  activerecord_version = ENV['ACTIVERECORD_VERSION']

  if activerecord_version == "edge"
    git "git://github.com/rails/rails.git" do
      gem "activerecord"
      gem "activesupport"
    end
  elsif activerecord_version && activerecord_version.strip != ""
    gem "activerecord", activerecord_version
  else
    gem "activerecord", "~> 3.0.0"
  end
  
end

