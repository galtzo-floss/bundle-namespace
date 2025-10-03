# frozen_string_literal: true

require_relative "lib/bundle/namespace/version"

Gem::Specification.new do |spec|
  spec.name = "bundle-namespace"
  spec.version = Bundle::Namespace::VERSION
  spec.authors = ["Peter H. Boling"]
  spec.email = ["peter.boling@gmail.com"]

  spec.summary = "Bundler plugin that adds namespace support for gem resolution"
  spec.description = "Extends Bundler's DSL with a namespace macro to support organization-scoped and user-scoped gem repositories, enabling differentiation between multiple flavors of the same gem from namespace-aware sources."
  spec.homepage = "https://github.com/pboling/bundle-namespace"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/pboling/bundle-namespace"
  spec.metadata["changelog_uri"] = "https://github.com/pboling/bundle-namespace/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/pboling/bundle-namespace/issues"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/bundle-namespace"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile bundler/ .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # NOTE: bundler is NOT a runtime dependency because this is a bundler plugin
  # Bundler must already be loaded when this plugin runs
  # We only require bundler >= 2.3.0 as a development/testing dependency

  # Development dependencies
  spec.add_development_dependency "bundler", ">= 2.3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "yard", "~> 0.9"
end
