# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "range"

require "set"

module Protocol
	module Media
		# An immutable set of compatible media ranges.
		class Set
			include Enumerable
			
			# Matches any type or subtype.
			class Any
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
				# Initialize an immutable collection of types.
				# @parameter types [Hash] The indexed subtype membership.
				def initialize(types)
					@types = types
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
				
			end
			
			ANY = Any.new.freeze
			
			private_constant :Any, :Types, :ANY
			
			# Incrementally constructs an immutable media set.
			class Builder
				# Initialize an empty media set builder.
				def initialize
					@types = {}
				end
				
				# Add a media range to the set under construction.
				# @parameter range [String | Object] The media range or compatible object.
				# @returns [self]
				def add(range)
					range = Range.for(range)
					range = Range.new(range.type, range.subtype)
					type = range.type.freeze
					subtype = range.subtype.freeze
					
					if @types.instance_of?(Any)
						return self
					elsif type == "*"
						@types = ANY
					elsif subtype == "*"
						@types[type] = ANY
					elsif subtypes = @types[type]
						unless subtypes.instance_of?(Any)
							subtypes.add(subtype)
						end
					else
						@types[type] = ::Set.new([subtype])
					end
					
					return self
				end
				
				alias << add
				
				# Compile the current ranges into an immutable set.
				# @returns [Set] The immutable media set.
				def build
					if @types.instance_of?(Any)
						types = @types
					else
						index = @types.to_h do |type, subtypes|
							if subtypes.instance_of?(Any)
								[type, subtypes]
							else
								[type, subtypes.dup.freeze]
							end
						end
						
						types = Types.new(index.freeze).freeze
					end
					
					return Set.send(:new, types).freeze
				end
			end
			
			# Construct an immutable set using a builder.
			# @yields {|builder| ...} The mutable builder.
			# @returns [Set] The immutable media set.
			def self.build
				builder = Builder.new
				
				if block_given?
					yield builder
				end
				
				return builder.build
			end
			
			# Convert a sequence of ranges into an immutable media set.
			#
			# @parameter ranges [Set | Enumerable] The existing set or media ranges.
			# @returns [Set] The immutable media set.
			def self.for(ranges)
				return ranges if ranges.instance_of?(self)
				
				return build do |builder|
					ranges.each do |range|
						builder << range
					end
				end
			end
			
			# Whether the set contains a compatible media type or range.
			# @parameter range [String | Object] The media type or range to match.
			# @returns [Boolean]
			def include?(range)
				range = Range.for(range)
				range = Range.new(range.type, range.subtype)
				
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
					range = Range.new(type, subtype, {}.freeze)
					range.type.freeze
					range.subtype.freeze
					yield range.freeze
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
			
			private
			
			def initialize(types)
				@types = types
			end
			
			private_class_method :new
		end
	end
end
