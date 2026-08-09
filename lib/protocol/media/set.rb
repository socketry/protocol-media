# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "range"

require "set"

module Protocol
	module Media
		# A set of compatible media ranges.
		class Set
			include Enumerable
			
			# An immutable set which matches any media range.
			class Any
				include Enumerable
				
				RANGE = Range.new("*", "*").freeze
				private_constant :RANGE
				
				# Whether the set contains a compatible media type or range.
				# @parameter media_range [String | Object] The media type or range to validate.
				# @returns [Boolean]
				def include?(media_range)
					media_range = Range.for(media_range)
					
					Range.build(media_range.type, media_range.subtype)
					
					return true
				end
				
				alias === include?
				alias match? include?
				
				# Enumerate the universal media range.
				# @yields {|media_range| ...} The universal media range.
				# @returns [Enumerator | self]
				def each
					return to_enum unless block_given?
					
					yield RANGE
					
					return self
				end
				
				# The number of membership ranges.
				# @returns [Integer]
				def size
					return 1
				end
				
				# Whether there are no membership ranges.
				# @returns [Boolean]
				def empty?
					return false
				end
				
				# Whether this set matches every media range.
				# @returns [Boolean]
				def universal?
					return true
				end
			end
			
			ANY = Any.new.freeze
			
			private_constant :Any, :ANY
			
			# Convert a sequence of ranges into a media set.
			#
			# Existing sets are returned unchanged, including their frozen state.
			#
			# @parameter media_ranges [Set | Enumerable] The existing set or media ranges.
			# @returns [Set] The existing set or a newly constructed immutable set.
			def self.for(media_ranges)
				# Preserve an existing media set:
				if media_ranges.instance_of?(self)
					return media_ranges
				end
				
				# Preserve the universal media set:
				if media_ranges.instance_of?(Any)
					return media_ranges
				end
				
				set = new(media_ranges)
				set.freeze
				
				if set.universal?
					return ANY
				end
				
				return set
			end
			
			# Initialize a new mutable media set with the given media ranges.
			#
			# Freezing the set compiles the ranges into an efficient immutable index.
			#
			# @parameter media_ranges [Enumerable] The existing media ranges.
			def initialize(media_ranges = [])
				@entries = []
				@types = nil
				
				media_ranges.each do |media_range|
					add(media_range)
				end
			end
			
			# Add a media range to the set under construction.
			# @parameter media_range [String | Object] The media range or compatible object.
			# @returns [self]
			def add(media_range)
				raise FrozenError, "can't modify frozen #{self.class}" if frozen?
				
				media_range = normalize(media_range)
				
				@entries << media_range
				@types = nil
				
				return self
			end
			
			alias << add
			
			# Freeze the media set, compiling its ranges into an efficient index.
			# @returns [self]
			def freeze
				return self if frozen?
				
				types = self.types
				@entries = nil
				
				unless types.instance_of?(Any)
					types.each_value(&:freeze)
					types.freeze
				end
				
				return super
			end
			
			# Whether the set contains a compatible media type or range.
			# @parameter media_range [String | Object] The media type or range to match.
			# @returns [Boolean]
			def include?(media_range)
				media_range = normalize(media_range)
				type = media_range.type
				subtype = media_range.subtype
				types = self.types
				
				if types.instance_of?(Any)
					return true
				end
				
				# A wildcard type matches any non-empty set:
				if type == "*"
					return !types.empty?
				end
				
				subtypes = types[type]
				
				# An unknown type cannot match:
				unless subtypes
					return false
				end
				
				# A wildcard subtype matches any known type:
				if subtype == "*"
					return true
				end
				
				# A type-wide wildcard matches every subtype:
				if subtypes.instance_of?(Any)
					return true
				end
				
				return subtypes.include?(subtype)
			end
			
			alias === include?
			alias match? include?
			
			# Enumerate the canonical media ranges which define membership.
			# @yields {|media_range| ...} Each canonical media range.
			# @returns [Enumerator | self]
			def each(&block)
				return to_enum unless block
				
				types = self.types
				
				if types.instance_of?(Any)
					types.each(&block)
					return self
				end
				
				types.each do |type, subtypes|
					if subtypes.instance_of?(Any)
						yield Range.new(type, "*")
					else
						subtypes.each do |subtype|
							yield Range.new(type, subtype)
						end
					end
				end
				
				return self
			end
			
			# The number of canonical membership ranges.
			# @returns [Integer]
			def size
				types = self.types
				
				if types.instance_of?(Any)
					return types.size
				end
				
				return types.sum do |_type, subtypes|
					subtypes.size
				end
			end
			
			# Whether the set contains no media ranges.
			# @returns [Boolean]
			def empty?
				return types.empty?
			end
			
			# Whether this set matches every media range.
			# @returns [Boolean]
			def universal?
				return types.instance_of?(Any)
			end
			
			private
			
			def types
				return @types ||= compile(@entries)
			end
			
			def compile(media_ranges)
				types = {}
				
				media_ranges.each do |media_range|
					type = media_range.type.freeze
					subtype = media_range.subtype.freeze
					
					if type == "*"
						return ANY
					elsif subtype == "*"
						types[type] = ANY
					elsif subtypes = types[type]
						unless subtypes.instance_of?(Any)
							subtypes.add(subtype)
						end
					else
						types[type] = ::Set.new([subtype])
					end
				end
				
				return types
			end
			
			def normalize(media_range)
				media_range = Range.for(media_range)
				return Range.build(media_range.type, media_range.subtype)
			end
		end
	end
end
