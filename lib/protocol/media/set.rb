# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "range"

module Protocol
	module Media
		# A set of compatible media ranges.
		class Set
			include Enumerable
			
			# Initialize a set with the given media ranges.
			# @parameter ranges [Array(String, Object)] The initial media ranges.
			def initialize(*ranges)
				@entries = {}
				
				ranges.each do |range|
					self.add(range)
				end
			end
			
			# Add a media range to the set.
			# @parameter range [String | Object] The media range or compatible object.
			# @returns [self]
			def add(range)
				range = Range.for(range)
				@entries[name(range)] = range
				
				return self
			end
			
			alias << add
			
			# Whether the set contains a compatible media type or range.
			# @parameter range [String | Object] The media type or range to match.
			# @returns [Boolean]
			def include?(range)
				range = Range.for(range)
				range_name = name(range)
				
				if @entries.key?(range_name)
					return true
				end
				
				@entries.each_value do |entry|
					if compatible?(range, entry)
						return true
					end
				end
				
				return false
			end
			
			alias === include?
			alias match? include?
			
			# Enumerate the registered media ranges in insertion order.
			# @yields {|range| ...} Each registered media range.
			# @returns [Enumerator | self]
			def each
				return to_enum unless block_given?
				
				@entries.each_value do |range|
					yield range
				end
				
				return self
			end
			
			# The number of registered media ranges.
			# @returns [Integer]
			def size
				return @entries.size
			end
			
			# Whether the set contains no media ranges.
			# @returns [Boolean]
			def empty?
				return @entries.empty?
			end
			
			# Freeze the set and its internal index.
			# @returns [self]
			def freeze
				return self if self.frozen?
				
				@entries.freeze
				super
			end
			
			private
			
			def name(range)
				return "#{range.type.downcase}/#{range.subtype.downcase}"
			end
			
			def compatible?(left, right)
				return match_component?(left.type, right.type) && match_component?(left.subtype, right.subtype)
			end
			
			def match_component?(left, right)
				return left == "*" || right == "*" || left.casecmp?(right)
			end
		end
	end
end
