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
			# @parameter range [Range | String] The media type or range.
			# @parameter object [Object] The object associated with the range.
			def []=(range, object)
				range = coerce(range)
				
				@entries[range.name] = [range, object]
			end
			
			# Find the object matching a media type or range.
			#
			# Exact type/subtype registrations take priority, followed by the first compatible registration.
			#
			# @parameter range [Range | String] The media type or range.
			# @returns [Object | nil] The matching object, if one exists.
			def [](range)
				if entry = lookup(coerce(range))
					entry.last
				end
			end
			
			# Find the first object matching an ordered sequence of media ranges.
			#
			# @parameter ranges [Enumerable] The media types or ranges in preference order.
			# @returns [Array(Object, Range | String) | nil] The matching object and original range, if one exists.
			def for(ranges)
				ranges.each do |range|
					if entry = lookup(coerce(range))
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
			
			def coerce(range)
				case range
				when Range
					range
				when String
					Range.parse(range)
				else
					raise TypeError, "Expected a media range, got: #{range.class}"
				end
			end
			
			def lookup(range)
				return @entries[range.name] if @entries.key?(range.name)
				
				@entries.each_value do |entry|
					return entry if range.match?(entry.first)
				end
				
				return nil
			end
		end
	end
end
