# Implementation Plan: Bundle::Namespace

Based on PRD.md - Created: October 3, 2025

---

## Overview

This implementation plan breaks down the Bundle::Namespace plugin development into actionable tasks, organized by phase and priority.

---

## Phase 1: Foundation (Current Phase)

### 1.1 Project Setup ✓ (Already Done)
- [x] Gem structure created
- [x] Basic module scaffold exists

### 1.2 Plugin Infrastructure (In Progress)
- [ ] Create plugin registration system
  - [ ] `lib/bundle/namespace/plugin.rb` - Main plugin class
  - [ ] `lib/bundle/namespace/hooks.rb` - Bundler hook integration
  - [ ] Register with Bundler plugin system

### 1.3 Core Data Structures
- [ ] `lib/bundle/namespace/dependency_extension.rb` - Extend Bundler::Dependency
- [ ] `lib/bundle/namespace/registry.rb` - Track namespace mappings
- [ ] `lib/bundle/namespace/errors.rb` - Custom error classes

### 1.4 DSL Extension
- [ ] `lib/bundle/namespace/dsl_extension.rb` - Add namespace macro
  - [ ] Implement `namespace(*namespaces, &block)` method
  - [ ] Track namespace stack with `@namespaces`
  - [ ] Modify dependency creation to include namespace metadata
  - [ ] Support both block syntax and option syntax

### 1.5 Basic Tests
- [ ] `spec/bundle/namespace/dsl_extension_spec.rb` - DSL tests
- [ ] `spec/bundle/namespace/registry_spec.rb` - Registry tests
- [ ] `spec/bundle/namespace/dependency_extension_spec.rb` - Dependency tests

---

## Phase 2: Resolution

### 2.1 Source Enhancement
- [ ] `lib/bundle/namespace/source_extensions.rb`
  - [ ] Extend Bundler::Source::Rubygems
  - [ ] Implement namespace-aware spec lookups
  - [ ] Add namespace path construction (/<namespace>/<gem-name>)
  - [ ] Implement namespace detection for sources

### 2.2 Resolver Integration
- [ ] `lib/bundle/namespace/resolver_extension.rb`
  - [ ] Extend Bundler::Resolver
  - [ ] Modify package identification to include namespace
  - [ ] Update version filtering logic
  - [ ] Add conflict detection for namespaced gems

### 2.3 Specification Enhancement
- [ ] `lib/bundle/namespace/specification_extension.rb`
  - [ ] Track namespace in gem specifications
  - [ ] Modify spec comparison to include namespace

### 2.4 Integration Tests
- [ ] `spec/integration/namespace_resolution_spec.rb`
- [ ] `spec/integration/source_namespace_spec.rb`

---

## Phase 3: Lockfile

### 3.1 Lockfile Generator
- [ ] `lib/bundle/namespace/lockfile_generator.rb`
  - [ ] Create YAML structure (source -> namespace -> gem)
  - [ ] Generate bundler-namespace-lock.yaml
  - [ ] Hook into Bundler's lockfile generation

### 3.2 Lockfile Parser
- [ ] `lib/bundle/namespace/lockfile_parser.rb`
  - [ ] Parse YAML lockfile
  - [ ] Validate structure
  - [ ] Merge namespace data into resolution

### 3.3 Lockfile Validation
- [ ] `lib/bundle/namespace/lockfile_validator.rb`
  - [ ] Check consistency between Gemfile, Gemfile.lock, and namespace lockfile
  - [ ] Detect stale namespace entries
  - [ ] Warn on conflicts

### 3.4 End-to-End Tests
- [ ] `spec/integration/lockfile_generation_spec.rb`
- [ ] `spec/integration/lockfile_parsing_spec.rb`

---

## Phase 4: Polish

### 4.1 Error Handling
- [ ] Implement all error classes from errors.rb
- [ ] Add helpful error messages
- [ ] Create error recovery strategies

### 4.2 Configuration
- [ ] `lib/bundle/namespace/configuration.rb`
  - [ ] Support .bundle/config integration
  - [ ] Implement strict_mode
  - [ ] Implement warn_on_missing
  - [ ] Custom lockfile path

### 4.3 Documentation
- [ ] Update README.md with usage examples
- [ ] Add YARD documentation to all public APIs
- [ ] Create USAGE.md with detailed examples
- [ ] Add inline code comments

### 4.4 Performance Optimization
- [ ] Profile namespace checking overhead
- [ ] Optimize hot paths
- [ ] Add benchmarking suite

### 4.5 Beta Release
- [ ] Version 0.1.0 release
- [ ] Announce to community
- [ ] Gather feedback

---

## Implementation Order (This Session)

### Step 1: Core Infrastructure ✅
1. Update gemspec with proper metadata
2. Create error classes
3. Create registry class
4. Create plugin registration

### Step 2: DSL Extension ✅
1. Implement DSL extension module
2. Add namespace tracking
3. Support both syntaxes (block and option)
4. Write tests

### Step 3: Dependency Extension
1. Extend dependency to store namespace
2. Update dependency comparison
3. Write tests

### Step 4: Basic Integration
1. Wire up plugin to Bundler
2. Test basic namespace declaration
3. Verify no breakage of existing functionality

---

## File Structure

```
lib/bundle/namespace/
├── version.rb (exists)
├── plugin.rb (new) - Main plugin entry point
├── hooks.rb (new) - Bundler hook registration
├── errors.rb (new) - Custom error classes
├── registry.rb (new) - Namespace tracking
├── configuration.rb (new) - Plugin configuration
├── dsl_extension.rb (new) - Gemfile DSL enhancement
├── dependency_extension.rb (new) - Dependency enhancement
├── source_extensions.rb (new) - Source enhancements
├── resolver_extension.rb (new) - Resolver enhancement
├── specification_extension.rb (new) - Spec enhancement
├── lockfile_generator.rb (new) - YAML lockfile generation
├── lockfile_parser.rb (new) - YAML lockfile parsing
└── lockfile_validator.rb (new) - Lockfile validation

spec/bundle/namespace/
├── namespace_spec.rb (exists)
├── dsl_extension_spec.rb (new)
├── registry_spec.rb (new)
├── dependency_extension_spec.rb (new)
├── lockfile_generator_spec.rb (new)
└── ... (more test files)

spec/integration/
├── namespace_resolution_spec.rb (new)
├── lockfile_generation_spec.rb (new)
└── ... (more integration tests)
```

---

## Dependencies to Add

```ruby
# In gemspec
spec.add_dependency("bundler", ">= 2.3.0")

# Development dependencies
spec.add_development_dependency("rspec", "~> 3.12")
spec.add_development_dependency("rake", "~> 13.0")
spec.add_development_dependency("rubocop", "~> 1.50")
spec.add_development_dependency("yard", "~> 0.9")
```

---

## Testing Strategy

### Unit Tests
- Test each module in isolation
- Mock Bundler internals
- 95%+ coverage target

### Integration Tests
- Use actual Gemfile processing
- Test with mock gem servers
- Verify lockfile generation

### Compatibility Tests
- Test with Bundler 2.3.x, 2.4.x, 2.5.x
- Test with Ruby 2.7, 3.0, 3.1, 3.2, 3.3

---

## Success Criteria

### Phase 1
- [ ] Plugin loads without errors
- [ ] DSL namespace block can be parsed
- [ ] Dependencies track namespace metadata
- [ ] Tests pass

### Phase 2
- [ ] Namespaced gems can be resolved (with mock source)
- [ ] Non-namespaced gems still work
- [ ] Namespace conflicts are detected

### Phase 3
- [ ] bundler-namespace-lock.yaml is generated
- [ ] Lockfile is parsed correctly
- [ ] Validation detects inconsistencies

### Phase 4
- [ ] All tests pass
- [ ] Documentation complete
- [ ] Performance impact < 5%
- [ ] Beta release published

---

**Next Steps**: Begin Phase 1 implementation starting with gemspec update and core infrastructure.

