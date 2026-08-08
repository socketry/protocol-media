# Getting Started

This guide explains how to represent, compare, and map media types with `protocol-media`.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add protocol-media
~~~

## Core Concepts

Applications commonly need to identify response formats, compare wildcard ranges, collect accepted formats, and associate formats with handlers. `protocol-media` separates those concerns into four small objects:

  - {ruby Protocol::Media::Type} represents a concrete media type such as `application/json`.
  - {ruby Protocol::Media::Range} represents a concrete or wildcard range such as `text/*`.
  - {ruby Protocol::Media::Set} collects accepted media ranges and tests compatible membership.
  - {ruby Protocol::Media::Map} associates supported types or ranges with application objects.

The gem deliberately does not parse HTTP headers or provide a media type registry. Protocol implementations can supply compatible range objects, while registry data and extension lookup are provided by `protocol-media-registry`.

## Media Types

Use {ruby Protocol::Media::Type.parse} when an application needs a concrete content type and its parameters:

``` ruby
require "protocol/media/type"

type = Protocol::Media::Type.parse("application/json; charset=utf-8")

type.type # => "application"
type.subtype # => "json"
type.parameters # => {"charset" => "utf-8"}
type.name # => "application/json"
```

Media type names are normalized to lowercase. Parameters are retained for serialization but do not change the type name.

A concrete {ruby Protocol::Media::Type} cannot contain wildcards:

``` ruby
Protocol::Media::Type.parse("text/*")
# Raises ArgumentError.
```

## Media Ranges

Use {ruby Protocol::Media::Range.parse} when matching one or more compatible media types:

``` ruby
require "protocol/media/range"
require "protocol/media/type"

range = Protocol::Media::Range.parse("image/*")
png = Protocol::Media::Type.parse("image/png")
json = Protocol::Media::Type.parse("application/json")

range.match?(png) # => true
range.match?(json) # => false
```

`*/*` matches every media type, while `text/*` matches every subtype under `text`. Partial wildcard tokens such as `text/*+json` are not valid ranges.

### Compatible Range Objects

{ruby Protocol::Media::Range.for} parses strings but preserves non-string objects. This allows an HTTP implementation to provide its own richer range object without depending on `protocol-media`:

``` ruby
range = Protocol::Media::Range.for("text/*")
# => Protocol::Media::Range

http_range = Struct.new(:type, :subtype, :parameters).new(
	"application",
	"json",
	{"q" => "0.8"},
)

Protocol::Media::Range.for(http_range).equal?(http_range)
# => true
```

Compatible objects must expose `type` and `subtype`. Other attributes, such as HTTP quality factors, remain owned by the protocol-specific object.

## Media Sets

Use {ruby Protocol::Media::Set} when validating a media type against several accepted ranges:

``` ruby
require "protocol/media/set"
require "protocol/media/type"

accepted = Protocol::Media::Set.for(["image/*", "application/pdf"])
media_type = Protocol::Media::Type.parse("image/png")

accepted.include?(media_type)
# => true
```

Strings are parsed with {ruby Protocol::Media::Range.for}. Sets are immutable and parameters do not affect membership:

``` ruby
accepted = Protocol::Media::Set.build do |builder|
	builder << "image/*"
	builder << "text/plain"
end

accepted.include?("text/plain; charset=utf-8")
# => true
```

Sets expose the canonical ranges which define their membership with {ruby Protocol::Media::Set#each}. Redundant ranges are removed: `image/*` replaces concrete `image` ranges, while `*/*` replaces every range. Use a set for compatible membership and a {ruby Protocol::Media::Map} when each range needs an associated handler or other value.

## Media Maps

Use {ruby Protocol::Media::Map} when an application supports several representations and needs to select a compatible handler:

``` ruby
require "json"
require "protocol/media/map"

renderers = Protocol::Media::Map.build do |builder|
	builder["application/json"] = ->(record){JSON.generate(record)}
	builder["text/plain"] = ->(record){record.inspect}
end

renderer = renderers["text/*"]
renderer.call({id: 10, name: "Example"})
# => "{:id=>10, :name=>\"Example\"}"
```

Concrete registrations populate their exact key and the first available `type/*` and `*/*` aliases. Register concrete server representations in the order they should be used for wildcard requests. Explicit wildcard registrations replace the corresponding alias and provide specificity-based fallbacks for otherwise unknown concrete types.

Parameters do not distinguish map entries:

``` ruby
versioned = Protocol::Media::Map.for(
	"application/json; version=2" => :versioned_json,
)

versioned["application/json"]
# => :versioned_json
```

Use the original matched range, rather than separate parameterized registrations, when request parameters affect rendering. The [Content Negotiation](../content-negotiation/index) guide shows this pattern with an HTTP `Accept` header.

## Registry Data

`protocol-media` models media types but does not bundle the media type registry. Use `protocol-media-registry` when mapping file extensions or registered names:

``` ruby
require "protocol/media/registry"

record = Protocol::Media::Registry.for_extension(".json")
record.type.name
# => "application/json"
```
