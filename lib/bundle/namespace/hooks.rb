# frozen_string_literal: true

require_relative "dsl_extension"
require_relative "dependency_extension"
require_relative "source_extensions"
require_relative "resolver_extension"
require_relative "specification_extension"

module Bundle
  module Namespace
    # Hooks to integrate with Bundler's lifecycle
    module Hooks
      class << self
        # Install all hooks
        def install!
          install_dsl_extension
          install_dependency_extension
          install_source_extensions
          install_resolver_extension
          install_specification_extension
        end

        private

        # Prepend DSL extension to Bundler::Dsl
        def install_dsl_extension
          return unless defined?(Bundler::Dsl)

          Bundler::Dsl.prepend(Bundle::Namespace::DslExtension) unless Bundler::Dsl.ancestors.include?(Bundle::Namespace::DslExtension)
        end

        # Prepend dependency extension to Bundler::Dependency
        def install_dependency_extension
          return unless defined?(Bundler::Dependency)

          unless Bundler::Dependency.ancestors.include?(Bundle::Namespace::DependencyExtension)
            Bundler::Dependency.prepend(Bundle::Namespace::DependencyExtension)
          end
        end

        # Prepend source extensions to Bundler::Source::Rubygems
        def install_source_extensions
          return unless defined?(Bundler::Source::Rubygems)

          unless Bundler::Source::Rubygems.ancestors.include?(Bundle::Namespace::SourceRubygemsExtension)
            Bundler::Source::Rubygems.prepend(Bundle::Namespace::SourceRubygemsExtension)
          end
        end

        # Prepend resolver extension to Bundler::Resolver
        def install_resolver_extension
          return unless defined?(Bundler::Resolver)

          unless Bundler::Resolver.ancestors.include?(Bundle::Namespace::ResolverExtension)
            Bundler::Resolver.prepend(Bundle::Namespace::ResolverExtension)
          end
        end

        # Prepend specification extension to remote and lazy specifications
        def install_specification_extension
          install_on_remote_specification
          install_on_lazy_specification
        end

        def install_on_remote_specification
          return unless defined?(Bundler::RemoteSpecification)

          unless Bundler::RemoteSpecification.ancestors.include?(Bundle::Namespace::SpecificationExtension)
            Bundler::RemoteSpecification.prepend(Bundle::Namespace::SpecificationExtension)
          end
        end

        def install_on_lazy_specification
          return unless defined?(Bundler::LazySpecification)

          unless Bundler::LazySpecification.ancestors.include?(Bundle::Namespace::SpecificationExtension)
            Bundler::LazySpecification.prepend(Bundle::Namespace::SpecificationExtension)
          end
        end
      end
    end
  end
end
