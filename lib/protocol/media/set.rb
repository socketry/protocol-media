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
			
			# An immutable set which matches any media range.
			class Any
				include Enumerable
				
				RANGE = Range.new("*", "*").freeze
				private_constant :RANGE
				
				# Whether the set contains a compatible media type or range.
				# @parameter range [String | Object] The media type or range to validate.
				# @returns [Boolean]
				def include?(media_range)
					media_range = Range.for(media_range)
					
					Range.build(media_range.type, media_range.subtype)
					
					return true
				end
				
				alias === include?
				alias match? include?
				
				# Enumerate the universal media range.
				# @yields {|range| ...} The universal media range.
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
			end
			
			ANY = Any.new.freeze
			
			private_constant :Any, :ANY
			
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
					if @types.instance_of?(Any)
						return self
					end
					
					range = Range.for(range)
					range = Range.build(range.type, range.subtype)
					type = range.type.freeze
					subtype = range.subtype.freeze
					
					if type == "*"
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
						return @types
					end
					
					return Set.new(@types).freeze
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
				if ranges.instance_of?(self) || ranges.instance_of?(Any)
					return ranges
				end
				
				return build do |builder|
					ranges.each do |range|
						builder << range
					end
				end
			end
			
			# Initialize a new media set with the given type index.
			#
			# @parameter types [Hash] The indexed media ranges.
			def initialize(types)
				@types = types
			end
			
			# Freeze the media set and its index.
			# @returns [self]
			def freeze
				return self if frozen?
				
				@types.each_value(&:freeze)
				@types.freeze
				
				return super
			end
			
			# Whether the set contains a compatible media type or range.
			# @parameter range [String | Object] The media type or range to match.
			# @returns [Boolean]
			def include?(range)
				range = normalize(range)
				type = range.type
				subtype = range.subtype
				
				if type == "*"
					return !@types.empty?
				elsif subtypes = @types[type]
					if subtype == "*"
						return true
					elsif subtypes.instance_of?(Any)
						return true
					else
						return subtypes.include?(subtype)
					end
				end
				
				return false
			end
			
			alias === include?
			alias match? include?
			
			# Enumerate the canonical media ranges which define membership.
			# @yields {|range| ...} Each canonical media range.
			# @returns [Enumerator | self]
			def each
				return to_enum unless block_given?
				
				@types.each do |type, subtypes|
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
				return @types.sum do |_type, subtypes|
					subtypes.size
				end
			end
			
			# Whether the set contains no media ranges.
			# @returns [Boolean]
			def empty?
				return @types.empty?
			end
			
			private
			
			def normalize(range)
				range = Range.for(range)
				return Range.build(range.type, range.subtype)
			end
		end
	end
end
