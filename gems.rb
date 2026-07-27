# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"
	gem "bake-releases"
end

group :test do
	gem "covered"
	gem "sus"
	gem "decode"
	
	gem "bake-test"
end
