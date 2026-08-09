# Protocol::Media

Provides a small representation of media types which can be shared by protocol implementations and registry backends.

[![Development Status](https://github.com/socketry/protocol-media/workflows/Test/badge.svg)](https://github.com/socketry/protocol-media/actions?workflow=Test)

## Usage

Please see the [project documentation](https://socketry.github.io/protocol-media/) for more details.

  - [Getting Started](https://socketry.github.io/protocol-media/guides/getting-started/index) - This guide explains how to represent, compare, and map media types with `protocol-media`.

  - [Content Negotiation](https://socketry.github.io/protocol-media/guides/content-negotiation/index) - This guide explains how to combine `protocol-media` with an HTTP parser to select an application representation.

## Releases

Please see the [project releases](https://socketry.github.io/protocol-media/releases/index) for all releases.

### v0.3.0

  - Replace media map and set builders with mutable collections that can be frozen after construction.
  - Simplify lazy compilation of media map and set indexes.

### v0.2.1

  - Introduce `Protocol::Media::Set` for compatible media range membership.
  - Make `Protocol::Media::Map` and `Protocol::Media::Set` immutable, with builders for incremental construction and indexed lookups.

## See Also

  - [Protocol::Media::Registry](https://github.com/socketry/protocol-media-registry) provides registry data and indexed lookup by media type or file extension.
