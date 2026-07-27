# Protocol::Media

Provides a small representation of media types which can be shared by protocol implementations and registry backends.

```ruby
require "protocol/media/type"

type = Protocol::Media::Type.parse("text/plain")
type.type # => "text"
type.subtype # => "plain"
```

Registry data and indexed lookup are provided separately by `protocol-media-data`.
