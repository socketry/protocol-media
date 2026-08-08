# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "range"

module Protocol
	module Media
		# Maps media types and ranges to objects using type/subtype compatibility.
		class Map
			# Initialize an empty media map.
			def initialize
				@entries = {}
				@index = {}
			end
			
			# Associate a media type or range with an object.
			#
			# @parameter range [String | Object] The media type or compatible range.
			# @parameter object [Object] The object associated with the range.
			def []=(range, object)
				range = Range.for(range)
				range_name = name(range)
				type = range.type.downcase
				subtype = range.subtype.downcase
				
				@entries[range_name] = object
				@index[range_name] = range_name
				
				if type == "*"
					@index["*/*"] = range_name
				elsif subtype == "*"
					@index["*/*"] ||= range_name
				else
					@index["#{type}/*"] ||= range_name
					@index["*/*"] ||= range_name
				end
			end
			
			# Find the object matching a media type or range.
			#
			# Exact type/subtype registrations take priority, followed by the first compatible registration.
			#
			# @parameter range [String | Object] The media type or compatible range.
			# @returns [Object | nil] The matching object, if one exists.
			def [](range)
				if entry_name = lookup(Range.for(range))
					@entries[entry_name]
				end
			end
			
			# Find the first object matching an ordered sequence of media ranges.
			#
			# @parameter ranges [Enumerable] The media types or ranges in preference order.
			# @returns [Array(Object, Range | String) | nil] The matching object and original range, if one exists.
			def for(ranges)
				ranges.each do |range|
					if entry_name = lookup(Range.for(range))
						return [@entries[entry_name], range]
					end
				end
				
				return nil
			end
			
			# Freeze the map and its internal entries.
			#
			# @returns [self] The frozen map.
			def freeze
				return self if self.frozen?
				
				@entries.freeze
				@index.freeze
				
				super
			end
			
			private
			
			def name(range)
				"#{range.type.downcase}/#{range.subtype.downcase}"
			end
			
			def lookup(range)
				type = range.type.downcase
				subtype = range.subtype.downcase
				range_name = "#{type}/#{subtype}"
				return @index[range_name] if @index.key?(range_name)
				
				unless type == "*" || subtype == "*"
					type_wildcard = "#{type}/*"
					if @entries.key?(type_wildcard)
						return type_wildcard
					end
				end
				
				if @entries.key?("*/*")
					return "*/*"
				end
				
				return nil
			end
		end
	end
end
