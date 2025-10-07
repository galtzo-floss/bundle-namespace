# frozen_string_literal: true

module Bundle
  module Namespace
    # Integration with Bundler's lifecycle to auto-generate namespace lockfiles
    module BundlerIntegration
      class << self
        # Hook into Bundler's install process
        def install!
          return unless defined?(Bundler)

          setup_install_hooks
          setup_update_hooks
          setup_check_hooks
        end

        private

        # Setup hooks for bundle install
        def setup_install_hooks
          # Hook after Gemfile evaluation to populate registry from lockfile
          Bundler::Dsl.class_eval do
            alias_method(:original_to_definition, :to_definition)

            def to_definition(lockfile, unlock)
              # Load namespace lockfile before resolution if it exists
              Bundle::Namespace::BundlerIntegration.load_namespace_lockfile

              original_to_definition(lockfile, unlock)
            end
          end

          # Hook after resolution to generate namespace lockfile
          if defined?(Bundler::Definition)
            Bundler::Definition.class_eval do
              alias_method(:original_lock, :lock)

              def lock(file, preserve_unknown_sections = false)
                result = original_lock(file, preserve_unknown_sections)

                # Generate namespace lockfile after main lockfile
                Bundle::Namespace::BundlerIntegration.generate_namespace_lockfile(self)

                result
              end
            end
          end
        end

        # Setup hooks for bundle update
        def setup_update_hooks
          # Update uses the same install hooks
        end

        # Setup hooks for bundle check
        def setup_check_hooks
          # Validate namespace lockfile during bundle check
        end

        # Load namespace lockfile if it exists
        def load_namespace_lockfile
          lockfile_path = Configuration.lockfile_path

          return unless File.exist?(lockfile_path)

          parser = LockfileParser.new(lockfile_path)
          parser.populate_registry!

          if Configuration.warn_on_missing?
            validator = LockfileValidator.new(parser)
            validator.validate!
            validator.report(Bundler.ui) if validator.warnings.any?
          end
        rescue StandardError => e
          Bundler.ui.warn("Failed to load namespace lockfile: #{e.message}")
        end

        # Generate namespace lockfile after resolution
        def generate_namespace_lockfile(definition)
          return unless Registry.size > 0

          generator = LockfileGenerator.new(definition)

          return unless generator.needed?

          if generator.generate!
            Bundler.ui.info("Namespace lockfile written to #{generator.lockfile_path}")
          else
            Bundler.ui.warn("Failed to write namespace lockfile")
          end
        rescue StandardError => e
          Bundler.ui.warn("Error generating namespace lockfile: #{e.message}")
        end
      end
    end
  end
end

# Auto-install integration hooks when loaded
Bundle::Namespace::BundlerIntegration.install! if defined?(Bundler)
