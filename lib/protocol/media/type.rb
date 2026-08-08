# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "range"

module Protocol
	module Media
		# A concrete media type and its parameters.
		class Type < Range
			# Parse strings and normalize compatible media type objects.
			#
			# @parameter value [String | Object] A media type string or compatible object.
			# @returns [Type] The normalized concrete media type.
			def self.for(value)
				if value.is_a?(String)
					return parse(value)
				end
				
				return build(value.type, value.subtype, value.parameters)
			end
			
			# Build a normalized concrete media type.
			#
			# @parameter type [String] The top-level type.
			# @parameter subtype [String] The subtype.
			# @parameter parameters [Hash] The media type parameters.
			# @returns [Type] The normalized concrete media type.
			def self.build(type, subtype, parameters = {})
				if type.include?("*") || subtype.include?("*")
					raise ArgumentError, "Media types cannot contain wildcards: #{type}/#{subtype}"
				end
				
				return super
			end
		end
	end
end
