# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
  - YAML-based namespace lockfile (bundler-namespace-lock.yaml)
  - Three-level lockfile structure: source → namespace → gems
  - Lockfile parser to restore namespace information
  - Lockfile validator with error and warning reporting
- Phase 4: Polish & Integration
  - Automatic bundler integration hooks
  - Auto-generation of namespace lockfile during bundle install
  - Auto-loading of namespace lockfile before resolution
  - Comprehensive README with usage examples
  - Complete test coverage (104 examples, 100% passing)

### Changed
- N/A (initial release)

### Deprecated
- N/A (initial release)

### Removed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Security
- N/A (initial release)

## [0.1.0] - TBD

### Added
- Initial beta release
- Full namespace support for Bundler
- Comprehensive documentation
- 100% test coverage

[Unreleased]: https://github.com/pboling/bundle-namespace/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/pboling/bundle-namespace/releases/tag/v0.1.0

