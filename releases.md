# Releases

## Unreleased

  - Replace media map and set builders with mutable collections that can be frozen after construction.
  - Simplify lazy compilation of media map and set indexes.

## v0.2.1

  - Introduce `Protocol::Media::Set` for compatible media range membership.
  - Make `Protocol::Media::Map` and `Protocol::Media::Set` immutable, with builders for incremental construction and indexed lookups.
