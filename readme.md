# Protocol::Media

Provides a small representation of media types which can be shared by protocol implementations and registry backends.

``` ruby
require "protocol/media/type"

type = Protocol::Media::Type.parse("text/plain; charset=utf-8")
type.type # => "text"
type.subtype # => "plain"
type.parameters # => {"charset" => "utf-8"}
```

Media ranges can represent wildcard types and match compatible concrete media types:

``` ruby
require "protocol/media/range"

range = Protocol::Media::Range.parse("text/*")
range.match?(type) # => true
```

Media maps associate supported media types with objects and select compatible entries:

``` ruby
require "protocol/media/map"

map = Protocol::Media::Map.new
map[type] = :text
map[range] # => :text
```

Registry data and indexed lookup are provided separately by `protocol-media-registry`.
