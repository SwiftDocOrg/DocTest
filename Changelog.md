# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added documentation and testing infrastructure for Linux support.
  #17 by @heckj and @mattt.
- Added `--verbose` command flag.
  #21 by @mattt.

### Fixed

- Fixed test runner to fail on unexpected errors.
  #24 by @mattt.

## [0.0.4] - 2020-04-26

### Changed

- Changed `Package.swift` to include `DocTest` library product.
  #15 by @mattt

## [0.0.3] - 2020-04-20

### Changed

- Changed `swift-doctest` to exit with nonzero status when tests fail.
  #11 by @heckj.

## [0.0.2] - 2020-04-19

### Fixed

- Fixed bug when `swift-doctest` is run and no expectations are found.
  c02403705 by @mattt.

## [0.0.1] - 2020-04-18

Initial release.

[unreleased]: https://github.com/SwiftDocOrg/doctest/compare/0.0.4...master
[0.0.4]: https://github.com/SwiftDocOrg/swift-doc/releases/tag/0.0.4
[0.0.3]: https://github.com/SwiftDocOrg/swift-doc/releases/tag/0.0.3
[0.0.2]: https://github.com/SwiftDocOrg/swift-doc/releases/tag/0.0.2
[0.0.1]: https://github.com/SwiftDocOrg/swift-doc/releases/tag/0.0.1
