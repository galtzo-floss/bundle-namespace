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

  spec.add_development_dependency("kettle-dev", "~> 1.1")                     # ruby >= 2.3.0
  spec.add_development_dependency("bundler-audit", "~> 0.9.2")                      # ruby >= 2.0.0

  spec.add_development_dependency("rake", "~> 13.0")                                # ruby >= 2.2.0

  spec.add_development_dependency("require_bench", "~> 1.0", ">= 1.0.4")            # ruby >= 2.2.0

  spec.add_development_dependency("appraisal2", "~> 3.0")                           # ruby >= 1.8.7, for testing against multiple versions of dependencies

  spec.add_development_dependency("kettle-test", "~> 1.0")                          # ruby >= 2.3

  spec.add_development_dependency("rspec-pending_for", "~> 0.0", ">= 0.0.17")       # ruby >= 2.3, used to skip specs on incompatible Rubies

  spec.add_development_dependency("ruby-progressbar", "~> 1.13")                    # ruby >= 0

  spec.add_development_dependency("stone_checksums", "~> 1.0", ">= 1.0.2")          # ruby >= 2.2.0

  # spec.add_development_dependency("erb", ">= 2.2")                                  # ruby >= 2.3.0, not SemVer, old rubies get dropped in a patch.

  spec.add_development_dependency("gitmoji-regex", "~> 1.0", ">= 1.0.3")            # ruby >= 2.3.0

  # spec.add_development_dependency("backports", "~> 3.25", ">= 3.25.1")  # ruby >= 0

  # spec.add_development_dependency("vcr", ">= 4")                        # 6.0 claims to support ruby >= 2.3, but fails on ruby 2.4

  # spec.add_development_dependency("webmock", ">= 3")                    # Last version to support ruby >= 2.3

end
