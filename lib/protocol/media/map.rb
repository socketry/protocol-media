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
					media_type = Range.for(media_type)
					media_type = Type.new(media_type.type, media_type.subtype)
					
					# Preserve the first registration as the default for wildcard queries:
					@index["*/*"] ||= object
					@index["#{media_type.type}/*"] ||= object
					@index[media_type.name] = object
				end
				
				# Compile the current registrations into an immutable map.
				# @returns [Map] The immutable media map.
				def build
					return Map.send(:new, @index.dup.freeze).freeze
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
			
			# Convert keyed entries into an immutable media map.
			#
			# @parameter entries [Map | Enumerable] The existing map or keyed media range entries.
			# @returns [Map] The immutable media map.
			def self.for(entries)
				return entries if entries.instance_of?(self)
				
				return build do |builder|
					entries.each do |range, object|
						builder[range] = object
					end
				end
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
			
			def initialize(index)
				@index = index
			end
			
			private_class_method :new
			
			def lookup(range)
				range = Range.new(range.type, range.subtype)
				return @index[range.name]
			end
		end
	end
end
