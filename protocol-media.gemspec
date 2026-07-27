# frozen_string_literal: true

require_relative "lib/protocol/media/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-media"
	spec.version = Protocol::Media::VERSION
	
	spec.summary = "Provides abstractions for working with media types."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/socketry/protocol-media"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/protocol-media/",
		"source_code_uri" => "https://github.com/socketry/protocol-media.git",
	}
	
	spec.files = Dir.glob(["{lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.2"
end
