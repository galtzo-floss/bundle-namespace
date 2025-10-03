# Bundle::Namespace

A Bundler plugin that adds namespace support for gem resolution, enabling a choice between alternate versions of a single gem in different namespaces, as well as multiple "flavors" of the same gem (partial support), from namespace-aware sources.

[![Gem Version](https://badge.fury.io/rb/bundle-namespace.svg)](https://badge.fury.io/rb/bundle-namespace)
[![Build Status](https://github.com/pboling/bundle-namespace/workflows/CI/badge.svg)](https://github.com/pboling/bundle-namespace/actions)
[![Maintainability](https://api.codeclimate.com/v1/badges/YOUR_BADGE/maintainability)](https://codeclimate.com/github/pboling/bundle-namespace/maintainability)

## What is this?

Bundle::Namespace is a Bundler plugin that extends Bundler's DSL to support namespaced gem resolution. This allows you to:

- Use the same gem name from different organizations/namespaces
- Differentiate between multiple "flavors" of the same gem
- Organize gems by namespace (similar to GitHub organizations)
- Maintain separate versions of the same gem for different purposes

## Installation

Install the plugin:

```bash
bundle plugin install bundle-namespace
```

Or add to your Gemfile:

```ruby
plugin 'bundle-namespace'
```

## Usage

### Basic Namespace Declaration

Use the `namespace` macro in your Gemfile, similar to the `platform` macro:

```ruby
# Block syntax - namespace within default source
namespace :myorg do
  gem 'shared-library', '~> 2.0'
  gem 'custom-middleware'
end

# Within a specific source
source 'https://gems.mycompany.com' do
  namespace :engineering do
    gem 'internal-tools', '~> 1.5'
  end
  
  namespace :security do
    gem 'internal-tools', '~> 2.0'  # Different version, same name!
  end
end

# Option syntax
gem 'my-gem', '~> 1.0', namespace: :myorg
```

### Multiple Namespaces

Handle the same gem from different namespaces:

```ruby
source 'https://rubygems.org' do
  namespace :myorganization do
    gem 'rails', '~> 7.0', github: 'myorganization/rails', branch: 'custom'
  end
end

# Or for multi-tenant applications
source 'https://gems.saas-platform.com' do
  namespace :tenant_a do
    gem 'custom-theme', '~> 1.0'
  end
  
  namespace :tenant_b do
    gem 'custom-theme', '~> 2.0'
  end
end
```

### Nested Namespaces

Namespaces can be nested for complex organization:

```ruby
namespace :parent do
  namespace :child do
    gem 'nested-gem'
  end
end
```

## How It Works

### 1. DSL Extension (Phase 1)
The plugin adds a `namespace` macro to Gemfile syntax, tracking which gems belong to which namespaces.

### 2. Resolution Enhancement (Phase 2)
During dependency resolution, the plugin:
- Makes gem sources namespace-aware
- Filters available gems by namespace
- Resolves dependencies considering namespaces
- Tracks namespace information in specifications

### 3. Lockfile Generation (Phase 3)
The plugin generates `bundler-namespace-lock.yaml` alongside `Gemfile.lock`:

```yaml
---
"https://gems.mycompany.com":
  engineering:
    internal-tools:
      version: 1.5.2
      dependencies:
        - thor
      platform: ruby
  security:
    internal-tools:
      version: 2.0.1
      dependencies:
        - thor
        - openssl
      platform: ruby
```

This lockfile ensures reproducible builds with namespace information.

## Configuration

Configure the plugin via `.bundle/config`:

```bash
# Enable strict mode (raise errors for unsupported sources)
bundle config set namespace.strict_mode true

# Disable warnings for ignored namespaces
bundle config set namespace.warn_on_missing false

# Custom lockfile path
bundle config set namespace.lockfile_path "config/namespace-lock.yaml"
```

Or in Ruby:

```ruby
Bundle::Namespace::Configuration.strict_mode = true
Bundle::Namespace::Configuration.warn_on_missing = false
Bundle::Namespace::Configuration.lockfile_path = "custom-path.yaml"
```

## Requirements

- Ruby >= 2.7.0
- Bundler >= 2.3.0

## Source Compatibility

### Namespace-Aware Sources

The plugin automatically detects if a gem source supports namespaces. For sources that do:
- Gems are fetched from `<namespace>/<gem-name>` paths
- Specs are filtered by namespace
- Multiple versions of the same gem can coexist

### Non-Namespace-Aware Sources

For sources that don't support namespaces:
- Namespace declarations are tracked but not enforced
- Standard gem resolution applies
- Warnings are shown (unless disabled)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

## Testing

```bash
# Run all tests
bundle exec rspec

# Run with documentation format
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/bundle/namespace/dsl_extension_spec.rb
```

## Project Structure

```
lib/bundle/namespace/
├── version.rb                    # Version information
├── errors.rb                     # Custom error classes
├── registry.rb                   # Namespace-to-gem registry
├── configuration.rb              # Plugin configuration
├── dsl_extension.rb             # Gemfile DSL namespace macro
├── dependency_extension.rb       # Namespace-aware dependencies
├── source_extensions.rb          # Namespace-aware sources
├── resolver_extension.rb         # Namespace-aware resolution
├── specification_extension.rb    # Namespace tracking in specs
├── lockfile_generator.rb        # Generate namespace lockfile
├── lockfile_parser.rb           # Parse namespace lockfile
├── lockfile_validator.rb        # Validate lockfile consistency
├── bundler_integration.rb       # Auto-integration with Bundler
├── hooks.rb                     # Extension installation
└── plugin.rb                    # Main plugin entry point
```

## Architecture

The plugin uses **module prepending** to minimally monkey-patch Bundler:

- `Bundler::Dsl` ← `DslExtension` (adds namespace macro)
- `Bundler::Dependency` ← `DependencyExtension` (tracks namespaces)
- `Bundler::Source::Rubygems` ← `SourceRubygemsExtension` (namespace-aware lookups)
- `Bundler::Resolver` ← `ResolverExtension` (namespace-aware resolution)
- `Bundler::RemoteSpecification` ← `SpecificationExtension` (namespace tracking)
- `Bundler::LazySpecification` ← `SpecificationExtension` (namespace tracking)

## Use Cases

### Enterprise Internal Gems

```ruby
source 'https://gems.mycompany.com' do
  namespace :platform_team do
    gem 'core-services', '~> 3.0'
    gem 'monitoring-toolkit'
  end
  
  namespace :security_team do
    gem 'core-services', '~> 2.5'  # Legacy compatibility
    gem 'security-scanner'
  end
end
```

### Testing Forked Gems

```ruby
source 'https://rubygems.org' do
  namespace :myorganization do
    gem 'rails', github: 'myorganization/rails', branch: 'custom-patches'
  end
end
```

### Multi-Tenant Applications

```ruby
source 'https://gems.saas-platform.com' do
  namespace :tenant_a do
    gem 'custom-theme', '~> 1.0'
  end
  
  namespace :tenant_b do
    gem 'custom-theme', '~> 2.0'
  end
end
```

## Troubleshooting

### Namespace Not Being Applied

1. Check if source supports namespaces
2. Enable warnings: `bundle config set namespace.warn_on_missing true`
3. Check `bundler-namespace-lock.yaml` was generated

### Lockfile Validation Errors

```bash
# Validate manually
bundle exec ruby -r bundle/namespace -e "
  parser = Bundle::Namespace::LockfileParser.new
  validator = Bundle::Namespace::LockfileValidator.new(parser)
  validator.validate!
  validator.report
"
```

### Reset Namespace Information

```bash
# Remove namespace lockfile
rm bundler-namespace-lock.yaml

# Clear registry (in Ruby)
Bundle::Namespace::Registry.clear!
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pboling/bundle-namespace.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bundle::Namespace project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pboling/bundle-namespace/blob/main/CODE_OF_CONDUCT.md).

## Credits

Created by Peter H. Boling

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
