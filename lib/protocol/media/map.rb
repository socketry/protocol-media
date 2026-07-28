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
			end
			
			# Associate a media type or range with an object.
			#
			# @parameter range [String | Object] The media type or compatible range.
			# @parameter object [Object] The object associated with the range.
			def []=(range, object)
				range = Range.for(range)
				
				@entries[name(range)] = [range, object]
			end
			
			# Find the object matching a media type or range.
			#
			# Exact type/subtype registrations take priority, followed by the first compatible registration.
			#
			# @parameter range [String | Object] The media type or compatible range.
			# @returns [Object | nil] The matching object, if one exists.
			def [](range)
				if entry = lookup(Range.for(range))
					entry.last
				end
			end
			
			# Find the first object matching an ordered sequence of media ranges.
			#
			# @parameter ranges [Enumerable] The media types or ranges in preference order.
			# @returns [Array(Object, Range | String) | nil] The matching object and original range, if one exists.
			def for(ranges)
				ranges.each do |range|
					if entry = lookup(Range.for(range))
						return [entry.last, range]
					end
				end
				
				return nil
			end
			
			# Freeze the map and its internal entries.
			#
			# @returns [self] The frozen map.
			def freeze
				unless frozen?
					@entries.each_value(&:freeze)
					@entries.freeze
				end
				
				super
			end
			
			private
			
			def name(range)
				"#{range.type.downcase}/#{range.subtype.downcase}"
			end
			
			def lookup(range)
				range_name = name(range)
				return @entries[range_name] if @entries.key?(range_name)
				
				@entries.each_value do |entry|
					return entry if match?(range, entry.first)
				end
				
				return nil
			end
			
			def match?(left, right)
				match_component?(left.type, right.type) && match_component?(left.subtype, right.subtype)
			end
			
			def match_component?(left, right)
				left == "*" || right == "*" || left.casecmp?(right)
			end
		end
	end
end
