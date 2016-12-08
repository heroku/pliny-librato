Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## 0.3.0

### Changed

- All metrics sent to librato will be reported as gauges. This means that
  `Pliny::Metrics.count` will be a gauge, to provide compatiblity with l2met
  "count#" entries, which are also submitted as gauges.

## 0.2.0
- Catch and report errors in async calls to the Librato API
