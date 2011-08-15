#!/bin/sh 

set -e

versions="rails_3_0 rails_3_1"

for version in $versions
do
  echo "Running BUNDLE_GEMFILE=test/${version} bundle exec rake..."
  BUNDLE_GEMFILE=test/${version}/Gemfile bundle install
  BUNDLE_GEMFILE=test/${version}/Gemfile bundle exec rake
done

echo 'Success!'