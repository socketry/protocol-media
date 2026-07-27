# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "version"

module Protocol
	module Media
		# A media type and its associated registry attributes.
		class Type
			# Parse a media type name.
			#
			# @parameter name [String] The media type name, e.g. `text/plain`.
			# @parameter options [Hash] Additional attributes passed to {#initialize}.
			# @returns [Type] The parsed media type.
			def self.parse(name, **options)
				type, separator, subtype = name.partition("/")
				
				unless separator == "/" && !type.empty? && !subtype.empty? && !subtype.include?("/")
					raise ArgumentError, "Invalid media type: #{name.inspect}"
				end
				
				new(type, subtype, **options)
			end
			
			# @attribute [String] The top-level type, e.g. `text`.
			attr_reader :type
			
			# @attribute [String] The subtype, e.g. `plain`.
			attr_reader :subtype
			
			# @attribute [Array(String) | Nil] Known filename extensions.
			attr_reader :extensions
			
			# @attribute [String | Nil] The transfer encoding conventionally used for this type.
			attr_reader :encoding
			
			# @parameter type [String] The top-level type.
			# @parameter subtype [String] The subtype.
			# @parameter extensions [Array(String) | Nil] Known filename extensions.
			# @parameter encoding [String | Nil] The conventional transfer encoding.
			def initialize(type, subtype, extensions: nil, encoding: nil)
				@type = type.downcase
				@subtype = subtype.downcase
				@extensions = extensions
				@encoding = encoding
			end
			
			# The complete media type name.
			#
			# @returns [String]
			def name
				"#{@type}/#{@subtype}"
			end
			
			alias to_s name
			alias to_str name
			
			# Compare this media type with another media type.
			def ==(other)
				other.is_a?(Type) && @type == other.type && @subtype == other.subtype
			end
			
			alias eql? ==
			
			# Generate a hash key consistent with {#eql?}.
			def hash
				[@type, @subtype].hash
			end
		end
	end
end
