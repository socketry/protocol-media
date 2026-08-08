# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "version"

require "strscan"

module Protocol
	module Media
		# A media range and its parameters.
		class Range
			TOKEN = /[!#$%&'*+\-.^_`|~0-9A-Z]+/i
			QUOTED_STRING = /"(?:.(?!(?<!\\)"))*.?"/
			MEDIA_TYPE = /(?<type>#{TOKEN})\/(?<subtype>#{TOKEN})/
			PARAMETER = /\s*;\s*(?<key>#{TOKEN})=((?<value>#{TOKEN})|(?<quoted_value>#{QUOTED_STRING}))/
			
			# Build a normalized media range.
			#
			# @parameter type [String] The top-level type.
			# @parameter subtype [String] The subtype.
			# @parameter parameters [Hash] The media range parameters.
			# @returns [Range] The normalized media range.
			def self.build(type, subtype = "*", parameters = {})
				type = type.downcase
				subtype = subtype.downcase
				
				unless valid_wildcard?(type, subtype)
					raise ArgumentError, "Invalid wildcards in media range: #{type}/#{subtype}"
				end
				
				return new(type, subtype, parameters)
			end
			
			# Parse strings into media ranges while preserving compatible objects.
			#
			# @parameter value [String | Object] A media range string or compatible object.
			# @returns [Range | Object] The parsed range or original object.
			def self.for(value)
				if value.is_a?(String)
					parse(value)
				else
					value
				end
			end
			
			# Parse a media range.
			#
			# @parameter text [String] The media range, including any parameters.
			# @parameter normalize_whitespace [Boolean] Whether to normalize whitespace in quoted parameter values.
			# @returns [Range] The parsed media range.
			def self.parse(text, normalize_whitespace = true)
				scanner = StringScanner.new(text)
				
				unless scanner.scan(MEDIA_TYPE)
					raise ArgumentError, "Invalid media range: #{text.inspect}"
				end
				
				type = scanner[:type]
				subtype = scanner[:subtype]
				parameters = parse_parameters(scanner, normalize_whitespace)
				
				unless scanner.eos?
					raise ArgumentError, "Invalid media range: #{text.inspect}"
				end
				
				return build(type, subtype, parameters)
			end
			
			# Parse media type parameters from the scanner.
			#
			# @parameter scanner [StringScanner] The scanner positioned after the type and subtype.
			# @parameter normalize_whitespace [Boolean] Whether to normalize whitespace in quoted values.
			# @returns [Hash] The parsed parameters.
			def self.parse_parameters(scanner, normalize_whitespace = true)
				parameters = {}
				
				while scanner.scan(PARAMETER)
					key = scanner[:key]
					
					if value = scanner[:value]
						parameters[key] = value
					elsif quoted_value = scanner[:quoted_value]
						parameters[key] = unquote(quoted_value, normalize_whitespace)
					end
				end
				
				parameters
			end
			
			# @attribute [String] The top-level type, e.g. `text` or `*`.
			attr_reader :type
			
			# @attribute [String] The subtype, e.g. `plain` or `*`.
			attr_reader :subtype
			
			# @attribute [Hash] The media range parameters.
			attr_reader :parameters
			
			# @parameter type [String] The top-level type.
			# @parameter subtype [String] The subtype.
			# @parameter parameters [Hash] The media range parameters.
			def initialize(type, subtype = "*", parameters = {})
				@type = type
				@subtype = subtype
				@parameters = parameters
			end
			
			# The complete media range name.
			#
			# @returns [String]
			def name
				"#{@type}/#{@subtype}"
			end
			
			alias mime_type name
			
			# Convert the media range and parameters to a string.
			#
			# @returns [String] The serialized media range.
			def to_s
				name + @parameters.collect do |key, value|
					"; #{key}=#{quote(value.to_s)}"
				end.join
			end
			
			alias to_str to_s
			
			# Freeze the media range and its direct values.
			# @returns [self]
			def freeze
				return self if frozen?
				
				@type.freeze
				@subtype.freeze
				@parameters.freeze
				
				return super
			end
			
			# Whether this range matches the given media type or range.
			#
			# @parameter other [Range] The media type or range to match.
			# @returns [Boolean] Whether the type and subtype are compatible.
			def match?(other)
				(@type == "*" || other.type == "*" || @type == other.type) &&
					(@subtype == "*" || other.subtype == "*" || @subtype == other.subtype)
			end
			
			alias === match?
			
			# Compare this media range with another media range.
			#
			# @parameter other [Object] The object to compare.
			# @returns [Boolean] Whether the values are equal.
			def ==(other)
				other.instance_of?(self.class) && @type == other.type && @subtype == other.subtype && @parameters == other.parameters
			end
			
			alias eql? ==
			
			# Generate a hash key consistent with {#eql?}.
			#
			# @returns [Integer] The hash value.
			def hash
				[self.class, @type, @subtype, @parameters].hash
			end
			
			private
			
			def self.valid_wildcard?(type, subtype)
				return subtype == "*" if type == "*"
				return false if type.include?("*")
				
				subtype == "*" || !subtype.include?("*")
			end
			private_class_method :valid_wildcard?
			
			def self.unquote(value, normalize_whitespace)
				value = value[1...-1]
				value.gsub!(/\\(.)/, '\\1')
				value.gsub!(/[\r\n]+\s+/, " ") if normalize_whitespace
				value
			end
			
			def quote(value)
				if value.match?(/\A#{TOKEN}\z/)
					value
				else
					"\"#{value.gsub(/["\\]/, "\\\\\\0")}\""
				end
			end
		end
	end
end
