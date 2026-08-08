# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "range"

module Protocol
	module Media
		# An immutable map from media types and ranges to objects using type/subtype compatibility.
		class Map
			UNDEFINED = Object.new.freeze
			private_constant :UNDEFINED
			
			# Incrementally constructs an immutable media map.
			class Builder
				# Initialize an empty media map builder.
				def initialize
					@entries = {}
					@index = {}
					@fallbacks = {}
				end
				
				# Associate a media type or range with an object.
				#
				# @parameter range [String | Object] The media type or compatible range.
				# @parameter object [Object] The object associated with the range.
				def []=(range, object)
					if frozen?
						raise FrozenError, "can't modify frozen #{self.class}"
					end
					
					range = Range.for(range)
					range_name = name(range)
					type = range.type.downcase
					subtype = range.subtype.downcase
					
					@entries[range_name] = object
					@index[range_name] = range_name
					
					if type == "*"
						@index["*/*"] = range_name
						@fallbacks[nil] = object
					elsif subtype == "*"
						@index["*/*"] ||= range_name
						@fallbacks[type.freeze] = object
					else
						@index["#{type}/*"] ||= range_name
						@index["*/*"] ||= range_name
					end
				end
				
				# Compile the current registrations into an immutable map.
				# @returns [Map] The immutable media map.
				def build
					return @result if defined?(@result)
					
					index = @index.to_h do |range_name, entry_name|
						[range_name.freeze, @entries[entry_name]]
					end
					
					# Explicit wildcard registrations provide fallbacks for concrete lookups:
					index.update(@fallbacks)
					
					@result = Map.send(:new, index.freeze)
					@entries.freeze
					@index.freeze
					@fallbacks.freeze
					freeze
					
					return @result
				end
				
				private
				
				def name(range)
					return "#{range.type.downcase}/#{range.subtype.downcase}"
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
			# Exact type/subtype registrations take priority, followed by explicit wildcard fallbacks.
			#
			# @parameter range [String | Object] The media type or compatible range.
			# @returns [Object | nil] The matching object, if one exists.
			def [](range)
				object = lookup(Range.for(range))
				
				if object.equal?(UNDEFINED)
					return nil
				end
				
				return object
			end
			
			# Find the first object matching an ordered sequence of media ranges.
			#
			# @parameter ranges [Enumerable] The media types or ranges in preference order.
			# @returns [Array(Object, Range | String) | nil] The matching object and original range, if one exists.
			def for(ranges)
				ranges.each do |range|
					object = lookup(Range.for(range))
					unless object.equal?(UNDEFINED)
						return [object, range]
					end
				end
				
				return nil
			end
			
			private
			
			def initialize(index)
				@index = index
				freeze
			end
			
			private_class_method :new
			
			def lookup(range)
				type = range.type.downcase
				subtype = range.subtype.downcase
				range_name = "#{type}/#{subtype}"
				object = @index.fetch(range_name, UNDEFINED)
				
				unless object.equal?(UNDEFINED)
					return object
				end
				
				unless type == "*" || subtype == "*"
					object = @index.fetch(type, UNDEFINED)
					unless object.equal?(UNDEFINED)
						return object
					end
				end
				
				return @index.fetch(nil, UNDEFINED)
			end
		end
	end
end
