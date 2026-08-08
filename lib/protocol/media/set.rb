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
			
			# Matches any type or subtype.
			class Any
				# Add components without changing universal membership.
				# @parameter components [Array(String)] The type and optional subtype.
				# @returns [self]
				def add(*components)
					return self
				end
				
				# Whether the components are included.
				# @parameter components [Array(String)] The type and optional subtype.
				# @returns [Boolean]
				def include?(*components)
					return true
				end
				
				# Enumerate the universal media range.
				# @yields {|type, subtype| ...} The wildcard type and subtype.
				# @returns [Enumerator | self]
				def each
					return to_enum unless block_given?
					
					yield "*", "*"
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
			end
			
			# Matches specific top-level types and their subtypes.
			class Types
				# Initialize an empty collection of types.
				def initialize
					@types = {}
				end
				
				# Add a type and subtype.
				# @parameter type [String] The top-level type.
				# @parameter subtype [String] The subtype.
				# @returns [Types | Any] The current or widened collection.
				def add(type, subtype)
					if type == "*"
						return Any.new
					elsif subtype == "*"
						@types[type] = Any.new
					elsif subtypes = @types[type]
						subtypes.add(subtype)
					else
						@types[type] = ::Set.new([subtype])
					end
					
					return self
				end
				
				# Whether the type and subtype are included.
				# @parameter type [String] The top-level type.
				# @parameter subtype [String] The subtype.
				# @returns [Boolean]
				def include?(type, subtype)
					if type == "*"
						return !@types.empty?
					elsif subtypes = @types[type]
						if subtype == "*"
							return true
						else
							return subtypes.include?(subtype)
						end
					end
					
					return false
				end
				
				# Enumerate the canonical membership ranges.
				# @yields {|type, subtype| ...} Each type and subtype.
				# @returns [Enumerator | self]
				def each
					return to_enum unless block_given?
					
					@types.each do |type, subtypes|
						if subtypes.instance_of?(Any)
							yield type, "*"
						else
							subtypes.each do |subtype|
								yield type, subtype
							end
						end
					end
					
					return self
				end
				
				# The number of canonical membership ranges.
				# @returns [Integer]
				def size
					return @types.sum do |_type, subtypes|
						subtypes.size
					end
				end
				
				# Whether there are no membership ranges.
				# @returns [Boolean]
				def empty?
					return @types.empty?
				end
				
				# Freeze the types and their subtype collections.
				# @returns [self]
				def freeze
					return self if self.frozen?
					
					@types.each_value(&:freeze)
					@types.freeze
					super
				end
			end
			
			private_constant :Any, :Types
			
			# Initialize a set with the given media ranges.
			# @parameter ranges [Array(String, Object)] The initial media ranges.
			def initialize(*ranges)
				@types = Types.new
				
				ranges.each do |range|
					self.add(range)
				end
			end
			
			# Add a media range to the set.
			# @parameter range [String | Object] The media range or compatible object.
			# @returns [self]
			def add(range)
				if frozen?
					raise FrozenError, "can't modify frozen #{self.class}"
				end
				
				range = canonical(Range.for(range))
				@types = @types.add(range.type, range.subtype)
				
				return self
			end
			
			alias << add
			
			# Whether the set contains a compatible media type or range.
			# @parameter range [String | Object] The media type or range to match.
			# @returns [Boolean]
			def include?(range)
				range = canonical(Range.for(range))
				
				return @types.include?(range.type, range.subtype)
			end
			
			alias === include?
			alias match? include?
			
			# Enumerate the canonical media ranges which define membership.
			# @yields {|range| ...} Each canonical media range.
			# @returns [Enumerator | self]
			def each
				return to_enum unless block_given?
				
				@types.each do |type, subtype|
					yield canonical(Range.new(type, subtype))
				end
				
				return self
			end
			
			# The number of canonical membership ranges.
			# @returns [Integer]
			def size
				return @types.size
			end
			
			# Whether the set contains no media ranges.
			# @returns [Boolean]
			def empty?
				return @types.empty?
			end
			
			# Freeze the set and its internal indexes.
			# @returns [self]
			def freeze
				return self if self.frozen?
				
				@types.freeze
				super
			end
			
			private
			
			def canonical(range)
				range = Range.new(range.type, range.subtype, {}.freeze)
				range.type.freeze
				range.subtype.freeze
				return range.freeze
			end
		end
	end
end
