# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "type"

module Protocol
	module Media
		# An immutable map from concrete media types to objects for range-based lookup.
		class Map
			# Incrementally constructs an immutable media map.
			class Builder
				# Initialize an empty media map builder.
				def initialize
					@index = {}
				end
				
				# Associate a concrete media type with an object.
				#
				# @parameter media_type [String | Object] The concrete media type or compatible object.
				# @parameter object [Object] The object associated with the media type.
				def []=(media_type, object)
					media_type = Type.for(media_type)
					
					# Preserve the first registration as the default for wildcard queries:
					@index["*/*"] ||= object
					@index["#{media_type.type}/*"] ||= object
					@index[media_type.name] = object
				end
				
				# Compile the current registrations into an immutable map.
				# @returns [Map] The immutable media map.
				def build
					return Map.new(@index).freeze
				end
			end
			
			# Construct an immutable map using a builder.
			# @yields {|builder| ...} The mutable builder.
			# @returns [Map] The immutable media map.
			def self.build
				builder = Builder.new
				
				if block_given?
					yield builder
				end
				
				return builder.build
			end
			
			# Convert keyed entries into a media map.
			#
			# Existing maps are returned unchanged, including their frozen state.
			#
			# @parameter entries [Map | Enumerable] The existing map or keyed media range entries.
			# @returns [Map] The existing map or a newly constructed immutable map.
			def self.for(entries)
				return entries if entries.instance_of?(self)
				
				return build do |builder|
					entries.each do |range, object|
						builder[range] = object
					end
				end
			end
			
			# Initialize a new media map with a given index.
			#
			# The index is retained without copying or freezing it.
			#
			# @parameter index [Hash] The keyed media range entries.
			def initialize(index)
				@index = index
			end
			
			# Freeze the media map and its index.
			# @returns [self]
			def freeze
				return self if frozen?
				
				@index.freeze
				
				return super
			end
			
			# Find the object matching a media type or range.
			#
			# @parameter range [String | Object] The media type or compatible range.
			# @returns [Object | nil] The matching object, if one exists.
			def [](range)
				return lookup(Range.for(range))
			end
			
			# Find the first object matching an ordered sequence of media ranges.
			#
			# @parameter ranges [Enumerable] The media types or ranges in preference order.
			# @returns [Array(Object, Range | String) | nil] The matching object and original range, if one exists.
			def for(ranges)
				ranges.each do |range|
					if object = lookup(Range.for(range))
						return [object, range]
					end
				end
				
				return nil
			end
			
			private
			
			def lookup(range)
				range = Range.build(range.type, range.subtype)
				return @index[range.name]
			end
		end
	end
end
