# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "type"

module Protocol
	module Media
		# A map from concrete media types to objects for range-based lookup.
		class Map
			# Convert keyed entries into a media map.
			#
			# Existing maps are returned unchanged, including their frozen state.
			#
			# @parameter entries [Map | Enumerable] The existing map or keyed media range entries.
			# @returns [Map] The existing map or a newly constructed immutable map.
			def self.for(entries)
				return entries if entries.instance_of?(self)
				
				return new(entries).freeze
			end
			
			# Initialize a new mutable media map with the given entries.
			#
			# Freezing the map compiles the entries into an efficient immutable index.
			#
			# @parameter entries [Enumerable] The keyed media type entries.
			def initialize(entries = [])
				@entries = {}
				@index = nil
				
				entries.each do |media_type, object|
					self[media_type] = object
				end
			end
			
			# Associate a concrete media type with an object.
			# @parameter media_type [String | Object] The concrete media type or compatible object.
			# @parameter object [Object] The object associated with the media type.
			def []=(media_type, object)
				raise FrozenError, "can't modify frozen #{self.class}" if frozen?
				
				media_type = Type.for(media_type)
				
				@entries[media_type.name] = [media_type, object]
				@index = nil
			end
			
			# Freeze the media map, compiling its entries into an efficient index.
			# @returns [self]
			def freeze
				return self if frozen?
				
				@index ||= compile(@entries)
				@entries = nil
				
				@index.freeze
				
				return super
			end
			
			# Find the object matching a media type or range.
			#
			# @parameter media_range [String | Object] The media type or compatible range.
			# @returns [Object | nil] The matching object, if one exists.
			def [](media_range)
				return lookup(Range.for(media_range))
			end
			
			# Find the first object matching an ordered sequence of media ranges.
			#
			# @parameter media_ranges [Enumerable] The media types or ranges in preference order.
			# @returns [Array(Object, Range | String) | nil] The matching object and original range, if one exists.
			def for(media_ranges)
				media_ranges.each do |media_range|
					if object = lookup(Range.for(media_range))
						return [object, media_range]
					end
				end
				
				return nil
			end
			
			private
			
			def lookup(media_range)
				media_range = Range.build(media_range.type, media_range.subtype)
				index = @index ||= compile(@entries)
				
				return index[media_range.name]
			end
			
			def compile(entries)
				index = {}
				
				entries.each_value do |media_type, object|
					# Preserve the first registration as the default for wildcard queries:
					index["*/*"] ||= object
					index["#{media_type.type}/*"] ||= object
					index[media_type.name] = object
				end
				
				return index
			end
		end
	end
end
