Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

## 0.6.1

### Fixes

- Fixes a thread safety issue introduced in 0.6.0. [#13](https://github.com/heroku/pliny-librato/pull/13)

## 0.6.0

### Added

- `Aggregator` and `CounterCache` from `librato-rack` are now leveraged
  to reduce the number of metrics submitted for a given flush. This will
  reduce the total number of measurements submitted, and have a much lower
  impact on Librato's rate limiting.

### Removed

- `count` is no longer supported as an initialization option. The queue is
   only flushed based on the provided `interval`, or by calling `#stop`.

## 0.5.2

### Fixed

- Removed potential deadlock when stopping the backend.

### Changed

- `Backend#stop` can no longer be called from within a `Signal.trap` block.

## 0.5.1

### Changed

- The default submission interval is now 60 seconds for consistency with
  l2met and this project's README.
- Metrics are now regularly submitted on the desired interval. Previously,
  a new metric would need to be queued after the interval expired.

## 0.5.0

### Added

- Metrics are now reported to Librato from within a thread to prevent blocking

### Changed

- The backend must be started with `#start` and stopped with `#stop`. For example
  `backend = Backend.new(opts).start`, `backend.stop`.

## 0.4.0

### Added

- The backend now queues metrics and sends in batches
- You can specify the `count` and `interval` for batch sends when initializing
  the backend.

### Removed

- `concurrent-ruby` is no longer a dependency.

## 0.3.0

### Changed

- All metrics sent to librato will be reported as gauges. This means that
  `Pliny::Metrics.count` will be a gauge, to provide compatiblity with l2met
  "count#" entries, which are also submitted as gauges.

## 0.2.0

### Changed

- Catch and report errors in async calls to the Librato API
