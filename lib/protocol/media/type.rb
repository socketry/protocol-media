# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "range"

module Protocol
	module Media
		# A concrete media type and its parameters.
		class Type < Range
			
			# @parameter type [String] The top-level type.
			# @parameter subtype [String] The subtype.
			# @parameter parameters [Hash] The media type parameters.
			def initialize(type, subtype, parameters = {})
				if type.include?("*") || subtype.include?("*")
					raise ArgumentError, "Media types cannot contain wildcards: #{type}/#{subtype}"
				end
				
				super
			end
		end
	end
end
