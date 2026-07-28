# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "version"

require "strscan"

module Protocol
	module Media
		# A concrete media type and its parameters.
		class Type
			TOKEN = /[!#$%&'*+\-.^_`|~0-9A-Z]+/i
			QUOTED_STRING = /"(?:.(?!(?<!\\)"))*.?"/
			MEDIA_TYPE = /(?<type>#{TOKEN})\/(?<subtype>#{TOKEN})/
			PARAMETER = /\s*;\s*(?<key>#{TOKEN})=((?<value>#{TOKEN})|(?<quoted_value>#{QUOTED_STRING}))/
			
			# Parse a concrete media type.
			#
			# @parameter text [String] The media type, including any parameters.
			# @parameter normalize_whitespace [Boolean] Whether to normalize whitespace in quoted parameter values.
			# @returns [Type] The parsed media type.
			def self.parse(text, normalize_whitespace = true)
				scanner = StringScanner.new(text)
				
				unless scanner.scan(MEDIA_TYPE)
					raise ArgumentError, "Invalid media type: #{text.inspect}"
				end
				
				type = scanner[:type]
				subtype = scanner[:subtype]
				parameters = parse_parameters(scanner, normalize_whitespace)
				
				unless scanner.eos?
					raise ArgumentError, "Invalid media type: #{text.inspect}"
				end
				
				new(type, subtype, parameters)
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
			
			# @attribute [String] The top-level type, e.g. `text`.
			attr_reader :type
			
			# @attribute [String] The subtype, e.g. `plain`.
			attr_reader :subtype
			
			# @attribute [Hash] The media type parameters.
			attr_reader :parameters
			
			# @parameter type [String] The top-level type.
			# @parameter subtype [String] The subtype.
			# @parameter parameters [Hash] The media type parameters.
			def initialize(type, subtype, parameters = {})
				if type.include?("*") || subtype.include?("*")
					raise ArgumentError, "Media types cannot contain wildcards: #{type}/#{subtype}"
				end
				
				@type = type.downcase
				@subtype = subtype.downcase
				@parameters = parameters
			end
			
			# The complete media type name.
			#
			# @returns [String]
			def name
				"#{@type}/#{@subtype}"
			end
			
			alias mime_type name
			
			# Convert the media type and parameters to a string.
			def to_s
				name + @parameters.collect do |key, value|
					"; #{key}=#{quote(value.to_s)}"
				end.join
			end
			
			alias to_str to_s
			
			# Compare this media type with another media type.
			def ==(other)
				other.is_a?(Type) && @type == other.type && @subtype == other.subtype && @parameters == other.parameters
			end
			
			alias eql? ==
			
			# Generate a hash key consistent with {#eql?}.
			def hash
				[@type, @subtype, @parameters].hash
			end
			
			private
			
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
