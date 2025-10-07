# Changelog

[![SemVer 2.0.0][📌semver-img]][📌semver] [![Keep-A-Changelog 1.0.0][📗keep-changelog-img]][📗keep-changelog]

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][📗keep-changelog],
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
and [yes][📌major-versions-not-sacred], platform and engine support are part of the [public API][📌semver-breaking].
Please file a bug if you notice a violation of semantic versioning.

[📌semver]: https://semver.org/spec/v2.0.0.html
[📌semver-img]: https://img.shields.io/badge/semver-2.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [0.1.0] - TBD

### Added

- Initial beta release
- Full namespace support for Bundler
- Comprehensive documentation
- 100% test coverage
- Initial implementation of Bundle::Namespace plugin
- Phase 1: Foundation
  - DSL extension with `namespace` macro for Gemfiles
  - Namespace registry to track gem-to-namespace mappings
  - Configuration system (strict_mode, warn_on_missing, lockfile_path)
  - Custom error classes for namespace conflicts and validation
  - Dependency extension to track namespaces in dependencies
- Phase 2: Resolution Enhancement
  - Source extensions for namespace-aware gem lookups
  - Resolver extensions for namespace-aware dependency resolution
  - Specification extensions to track namespaces in gem specs
  - Automatic namespace detection based on registered dependencies
- Phase 3: Lockfile Generation
  - YAML-based namespace lockfile (bundle-namespace-lock.yaml)
  - Three-level lockfile structure: source → namespace → gems
  - Lockfile parser to restore namespace information
  - Lockfile validator with error and warning reporting
- Phase 4: Polish & Integration
  - Automatic bundler integration hooks
  - Auto-generation of namespace lockfile during bundle install
  - Auto-loading of namespace lockfile before resolution
  - Comprehensive README with usage examples
  - Complete test coverage (104 examples, 100% passing)

[Unreleased]: https://github.com/galtzo-floss/bundle-namespace/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/galtzo-floss/bundle-namespace/releases/tag/v0.1.0
