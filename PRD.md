# Product Requirements Document: Bundle::Namespace

**Version:** 1.0  
**Date:** October 3, 2025  
**Project:** bundle-namespace  
**Type:** Bundler Plugin (RubyGem)

---

## Executive Summary

Bundle::Namespace is a Bundler plugin that extends Bundler's DSL to support namespaced gem resolution. This allows developers to differentiate between multiple "flavors" of the same gem from namespace-aware sources, such as organization-scoped or user-scoped gem repositories.

---

## Problem Statement

Current Bundler implementation does not support namespace differentiation for gems from the same source. When multiple organizations or users publish gems with the same name, there is no built-in mechanism to:

1. Specify which namespace (organization/user) a gem should be resolved from
2. Resolve gems with the same name from different namespaces
3. Track namespace information in the lockfile for reproducible builds

This limitation prevents the use of scoped/namespaced gem repositories, which are common in private gem servers and organizational gem hosting.

---

## Goals

### Primary Goals
1. Add a `namespace` DSL macro to Gemfile syntax, modeled after the existing `platform` macro
2. Support namespace-aware gem resolution from compatible sources
3. Generate a supplementary lockfile to track namespace dependencies
4. Maintain backward compatibility with existing Bundler functionality
5. Minimize monkey-patching through use of module prepending

### Secondary Goals
1. Provide clear error messages when namespace conflicts occur
2. Support namespace inheritance from source blocks
3. Enable seamless integration with existing Bundler workflows

---

## Target Users

1. **Enterprise Ruby Developers**: Teams using private gem servers with organizational namespaces
2. **Open Source Maintainers**: Projects that need to test different forks of the same gem
3. **DevOps Engineers**: Teams managing multiple versions of infrastructure gems across organizations

---

## Functional Requirements

### 1. DSL Enhancement: `namespace` Macro

#### 1.1 Syntax and Structure

The `namespace` macro shall follow the same pattern as the existing `platforms` macro:

```ruby
# Top-level namespace (applies to default source)
namespace :acme_corp do
  gem 'custom-middleware'
end

# Top-level namespace specified per gem
gem 'dirigible', namespace: :beluga

# Namespace within a specific source
source 'https://gems.example.com' do
  namespace :engineering do
    gem 'internal-tools', '~> 1.5'
  end
end

# Another custom source and namespaces
source 'https://example.org' do
  gem 'bongo', namespace: :horton
  namespace :goblets do
    gem 'sharks'
    gem 'goats'
  end
end
```

#### 1.2 Behavior Specifications

- **Namespace Scope**: When `namespace` is used at the top level, it applies to the default/global RubyGems source
- **Source Nesting**: When used within a `source` block, the namespace is scoped to that specific source
- **Multiple Namespaces**: Multiple namespace blocks can exist for the same source
- **Gem Declaration**: Gems declared within a namespace block are resolved with the namespace prefix
- **Namespace Format**: Namespace tokens shall be symbols or strings, similar to GitHub usernames/organizations

#### 1.3 DSL Implementation Details

Based on Bundler DSL architecture (`bundler/lib/bundler/dsl.rb`):

- Implement `namespace(*namespaces, &block)` method in DSL
- Follow the pattern of `platforms` method (lines 200-209 in bundler/lib/bundler/dsl.rb):
  - Accept variable arguments for namespace names
  - Use instance variable stack (`@namespaces`) to track active namespaces
  - Yield to block for nested gem declarations
  - Ensure proper cleanup after block execution
- Integrate with `add_dependency` method to attach namespace metadata to dependencies

### 2. Dependency Resolution Enhancement

#### 2.1 Source Modification

Extend `Bundler::Source::Rubygems` (and other applicable sources):

- **Namespace-Aware Specs**: Modify gem specification lookups to include namespace prefix
- **Path Construction**: For namespace-aware sources, construct gem paths as `/<namespace>/<gem-name>`
- **Fallback Behavior**: For non-namespace-aware sources, ignore namespace (backward compatibility)

#### 2.2 Resolver Integration

Enhance `Bundler::Resolver` (`bundler/lib/bundler/resolver.rb`):

- **Package Identification**: Include namespace in package identification
- **Version Constraints**: Apply namespace when filtering available versions
- **Conflict Detection**: Detect and report conflicts between namespaced and non-namespaced gems

#### 2.3 Dependency Metadata

Extend `Bundler::Dependency` (`bundler/lib/bundler/dependency.rb`):

- Add `namespace` accessor method
- Store namespace in `@options` hash (similar to `platforms`, `env`, etc.)
- Include namespace in dependency comparison logic

### 3. Lockfile Enhancement

#### 3.1 Primary Lockfile (Gemfile.lock)

- **No Breaking Changes**: Maintain 100% backward compatibility
- **Namespace Hints**: Consider adding namespace comments (optional, if safe)

#### 3.2 Secondary Lockfile (bundler-namespace-lock.yaml)

Create a new YAML-based lockfile structure:

```yaml
# bundler-namespace-lock.yaml
---
"https://rubygems.org":
  myorg:
    shared-library:
      version: 1.2.3
      dependencies:
        - activesupport
    rails-extensions:
      version: 2.1.0
      dependencies: []

"https://gems.example.com":
  engineering:
    internal-tools:
      version: 1.5.2
      dependencies:
        - thor
  security:
    internal-tools:
      version: 2.0.1
      dependencies:
        - thor
        - openssl
```

#### 3.3 Lockfile Generation

Extend `Bundler::LockfileGenerator` (`bundler/lib/bundler/lockfile_generator.rb`):

- Create `NamespaceLockfileGenerator` class
- Generate YAML structure with three-level hierarchy:
  1. **Source URLs** (quoted strings as YAML keys)
  2. **Namespace tokens** (symbols or strings)
  3. **Gem names** with version and dependency metadata

#### 3.4 Lockfile Parsing

Create lockfile parser for namespace lockfile:

- Read and validate YAML structure
- Merge namespace information during dependency resolution
- Validate consistency between Gemfile, Gemfile.lock, and bundler-namespace-lock.yaml

### 4. Plugin Architecture

#### 4.1 Plugin Registration

Implement as a standard Bundler plugin (`Bundler::Plugin`):

```ruby
# lib/bundle/namespace/plugin.rb
module Bundle
  module Namespace
    class Plugin < Bundler::Plugin::API
      # Register hooks and patches
    end
  end
end
```

#### 4.2 Integration Points

Based on `bundler/lib/bundler/plugin.rb` and `bundler/lib/bundler/plugin/api.rb`:

- **Hook Registration**: Use `Bundler::Plugin.add_hook` for lifecycle integration
- **DSL Extension**: Prepend module to `Bundler::Dsl` to add `namespace` method
- **Source Patching**: Prepend to `Bundler::Source::Rubygems` for namespace-aware lookups
- **Resolver Patching**: Prepend to `Bundler::Resolver` for namespace-aware resolution
- **Lockfile Hook**: Hook into lockfile generation process

#### 4.3 Installation

Standard plugin installation:

```bash
bundle plugin install bundle-namespace
```

Or via Gemfile:

```ruby
plugin 'bundle-namespace'
```

---

## Technical Specifications

### 5. Implementation Strategy

#### 5.1 Module Prepending Pattern

Use Ruby's `Module#prepend` to minimize monkey-patching:

```ruby
module Bundle
  module Namespace
    module DslExtension
      def namespace(*namespaces, &block)
        @namespaces ||= []
        @namespaces.concat(namespaces)
        yield
      ensure
        namespaces.each { @namespaces.pop }
      end
      
      # Override add_dependency to include namespace
      def add_dependency(name, version = nil, options = {})
        options["namespace"] = @namespaces.last if @namespaces&.any?
        super
      end
    end
  end
end

# Apply with prepend
Bundler::Dsl.prepend(Bundle::Namespace::DslExtension)
```

#### 5.2 Source Enhancement

```ruby
module Bundle
  module Namespace
    module SourceRubygemsExtension
      def specs
        index = super
        # Filter/transform specs based on namespace
        apply_namespace_filtering(index)
      end
      
      def namespace_aware?
        # Check if source supports namespaces
        # Could be via HTTP header, API endpoint, etc.
      end
      
      private
      
      def apply_namespace_filtering(index)
        # Implementation details
      end
    end
  end
end

Bundler::Source::Rubygems.prepend(Bundle::Namespace::SourceRubygemsExtension)
```

#### 5.3 Resolver Enhancement

```ruby
module Bundle
  module Namespace
    module ResolverExtension
      def setup_solver
        result = super
        enhance_with_namespace_awareness(result)
        result
      end
      
      private
      
      def enhance_with_namespace_awareness(solver_components)
        # Modify package identification to include namespace
      end
    end
  end
end

Bundler::Resolver.prepend(Bundle::Namespace::ResolverExtension)
```

### 6. Data Structures

#### 6.1 Dependency Options

Extend the options hash used in `Bundler::Dependency`:

```ruby
{
  "source" => <Source object>,
  "namespace" => "myorg",  # NEW
  "platforms" => [...],
  "group" => :default,
  # ... other existing options
}
```

#### 6.2 Namespace Registry

Track namespace-to-source mappings:

```ruby
module Bundle
  module Namespace
    class Registry
      # Maps: source_uri => namespace => [gem_names]
      @namespaces = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
      
      def self.register(source, namespace, gem_name)
        @namespaces[source.to_s][namespace.to_s] << gem_name
      end
      
      def self.gems_for(source, namespace)
        @namespaces[source.to_s][namespace.to_s]
      end
    end
  end
end
```

### 7. Error Handling

#### 7.1 Namespace Conflict Errors

```ruby
class NamespaceConflictError < Bundler::GemfileError
  def initialize(gem_name, namespace1, namespace2)
    super("Gem '#{gem_name}' specified in multiple namespaces: " \
          "#{namespace1} and #{namespace2}")
  end
end
```

#### 7.2 Unsupported Source Errors

```ruby
class NamespaceNotSupportedError < Bundler::GemfileError
  def initialize(source)
    super("Source '#{source}' does not support namespaces")
  end
end
```

### 8. Configuration

#### 8.1 Plugin Configuration

Support configuration via `.bundle/config`:

```bash
bundle config set namespace.strict_mode true
bundle config set namespace.warn_on_missing false
```

#### 8.2 Configuration Options

- `namespace.strict_mode`: Raise errors if namespace-aware source doesn't support namespaces
- `namespace.warn_on_missing`: Warn when namespace is ignored by non-supporting sources
- `namespace.lockfile_path`: Custom path for namespace lockfile

---

## Non-Functional Requirements

### 9. Performance

- **Resolution Time**: Namespace checking should add < 5% overhead to resolution time
- **Memory Usage**: Namespace metadata should add < 10% to memory usage
- **Lockfile Size**: Secondary lockfile should be < 50% size of primary lockfile

### 10. Compatibility

- **Bundler Versions**: Support Bundler 2.3.x and higher (where plugin API is stable)
- **Ruby Versions**: Support Ruby 2.7+ (matching Bundler's requirements)
- **Backward Compatibility**: Gemfiles without `namespace` blocks work identically
- **Source Compatibility**: Graceful degradation for non-namespace-aware sources

### 11. Testing

- **Unit Tests**: 95%+ code coverage
- **Integration Tests**: Test with real Bundler workflow
- **Compatibility Tests**: Test against multiple Bundler/Ruby versions
- **Performance Tests**: Benchmark resolution time impact

---

## Dependencies

### 12. External Dependencies

- **bundler** (>= 2.3.0): Core dependency
- **yaml**: For lockfile generation (stdlib)

### 13. Development Dependencies

- **rspec** (~> 3.12): Testing framework
- **rspec-core** (~> 3.12): Testing core
- **rake** (~> 13.0): Build tasks
- **rubocop** (~> 1.50): Code linting
- **yard**: Documentation generation

---

## Deliverables

### 14. Phase 1: Foundation

- [ ] Plugin infrastructure and registration
- [ ] Basic `namespace` DSL method implementation
- [ ] Dependency metadata enhancement
- [ ] Unit tests for DSL functionality

### 14.1 Phase 2: Resolution

- [ ] Source enhancement for namespace-aware lookups
- [ ] Resolver integration for namespace-aware resolution
- [ ] Namespace registry implementation
- [ ] Integration tests for resolution

### 14.2 Phase 3: Lockfile

- [ ] Namespace lockfile generator
- [ ] Namespace lockfile parser
- [ ] Lockfile validation logic
- [ ] End-to-end tests

### 14.3 Phase 4: Polish

- [ ] Error handling and messaging
- [ ] Configuration options
- [ ] Documentation (README, YARD docs)
- [ ] Performance optimization
- [ ] Beta release

---

## Success Metrics

### 15. Adoption Metrics

- **Installation Count**: 100+ installations in first month
- **GitHub Stars**: 50+ stars in first quarter
- **Issue Resolution**: < 7 day average response time

### 16. Quality Metrics

- **Test Coverage**: ≥ 95%
- **Bug Reports**: < 5 critical bugs in first release
- **Performance Impact**: < 5% overhead on standard operations

---

## Risks and Mitigations

### 17. Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Bundler internal API changes | High | Medium | Pin to specific Bundler versions; use conservative prepending |
| Performance degradation | Medium | Low | Benchmark early; optimize hot paths |
| Namespace conflict with existing gems | High | Low | Clear documentation; strict validation |
| Source incompatibility | Medium | High | Graceful fallback; clear error messages |

### 18. Operational Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Low adoption | Medium | Medium | Clear documentation; example use cases |
| Maintenance burden | Medium | Medium | Automated testing; clear contribution guidelines |
| Breaking changes in Bundler | High | Low | Pin dependencies; test against Bundler pre-releases |

---

## Future Enhancements

### 19. Potential Features (Post-v1.0)

1. **Namespace Aliases**: Allow aliasing namespaces for shorter syntax
2. **Namespace Inheritance**: Support nested namespace hierarchies
3. **Multiple Namespace Lockfiles**: Support splitting namespaces across files
4. **Namespace Autodetection**: Automatically detect namespace from git remote
5. **Namespace Verification**: Cryptographic verification of namespace ownership
6. **IDE Integration**: Language server support for namespace completion

---

## Appendices

### A. References

- Bundler Documentation: https://bundler.io/docs.html
- Bundler Plugin Guide: https://bundler.io/guides/bundler_plugins.html
- Bundler Source Code: https://github.com/rubygems/rubygems (bundler subdirectory)
- RubyGems Specification: https://guides.rubygems.org/specification-reference/

### B. Glossary

- **Namespace**: A scope identifier (e.g., organization or user name) that prefixes gem names
- **Source**: A gem repository endpoint (e.g., rubygems.org, custom gem server)
- **DSL**: Domain-Specific Language (Bundler's Gemfile syntax)
- **Resolution**: The process of determining which gem versions satisfy dependencies
- **Lockfile**: File recording exact versions of resolved dependencies

---

**Document End**

*This PRD is a living document and will be updated as requirements evolve during implementation.*

