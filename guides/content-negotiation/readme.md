# Content Negotiation

This guide explains how to combine `protocol-media` with an HTTP parser to select an application representation.

## Overview

HTTP content negotiation has two separate responsibilities:

  - The HTTP layer parses the `Accept` header and orders ranges according to HTTP quality and preference rules.
  - The application layer maps those ordered ranges to representations it can produce.

Keeping this boundary explicit allows `protocol-http` to implement standard HTTP parsing without depending on `protocol-media`, while application frameworks can use {ruby Protocol::Media::Map} for their own policy.

## Register Representations

Register the concrete representations the application can produce. Registration order determines the fallback for wildcard ranges when there is no exact registration:

``` ruby
require "json"
require "protocol/media/map"

representations = Protocol::Media::Map.build do |builder|
	builder["application/json"] = lambda do |record, version: "1"|
		JSON.generate(record.merge(schema_version: version))
	end
	builder["text/plain"] = ->(record){record.inspect}
end
```

Register concrete response types rather than client ranges. A server generally produces `application/json`, even when a client requests `application/*` or `*/*`.

## Parse HTTP Preferences

The HTTP parser remains responsible for header syntax and quality ordering. Its range objects can be passed directly to {ruby Protocol::Media::Map#for} because the map only requires `type` and `subtype`:

``` ruby
require "protocol/http/header/accept"

accept = Protocol::HTTP::Header::Accept.parse(
	"text/*;q=0.5, application/json;q=1.0",
)

media_ranges = accept.media_ranges.sort
renderer, media_range = representations.for(media_ranges)

renderer.call({id: 10, name: "Example"})
# => "{\"id\":10,\"name\":\"Example\",\"schema_version\":\"1\"}"
```

{ruby Protocol::Media::Map#for} returns both the mapped object and the original range. Returning the original object preserves HTTP-specific state such as parameters and quality factors.

## Handle Request Parameters

Applications can inspect parameters on the selected HTTP range without teaching the media map about HTTP semantics:

``` ruby
renderer, media_range = representations.for(media_ranges)

if renderer
	version = media_range.parameters.fetch("version", "1")
	record = {id: 10, name: "Example"}
	body = renderer.call(record, version: version)
end
```

Parameters do not participate in map compatibility. They are application inputs associated with the selected range, not separate map keys.

## Handle Missing Headers

HTTP defines a missing `Accept` header as accepting any media type. The HTTP-facing application should install that policy explicitly:

``` ruby
if accept_header && !accept_header.empty?
	media_ranges = Protocol::HTTP::Header::Accept.parse(accept_header).media_ranges.sort
else
	media_ranges = [Protocol::Media::Range.parse("*/*")]
end

renderer, media_range = representations.for(media_ranges)
```

This policy belongs at the HTTP application boundary rather than in {ruby Protocol::Media::Map}, which can also be used outside HTTP.

## Handle No Match

When no registered representation matches, {ruby Protocol::Media::Map#for} returns `nil`. An HTTP application would normally return `406 Not Acceptable`:

``` ruby
if match = representations.for(media_ranges)
	renderer, media_range = match
	response_body = renderer.call(record)
else
	response_body = nil
	response_status = 406
end
```

## Best Practices

  - Sort HTTP ranges before passing them to the map; the map preserves the supplied order.
  - Register concrete server representations in deterministic fallback order.
  - Keep protocol-specific parameters on the original range object.
  - Handle missing headers and `406 Not Acceptable` at the HTTP or framework boundary.

## Common Pitfalls

{ruby Protocol::Media::Map} does not parse a comma-separated `Accept` header, sort quality factors, or decide HTTP response status. Passing a complete header string to the map attempts to parse it as one media range. Parse the header with an HTTP implementation first.

Map keys are identified by type and subtype. Registering the same type with different parameters replaces the existing entry rather than creating a parameter-specific variant.
