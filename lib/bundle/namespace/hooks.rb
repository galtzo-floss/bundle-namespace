# frozen_string_literal: true

require_relative "dsl_extension"
require_relative "dependency_extension"

module Bundle
  module Namespace
    # Hooks to integrate with Bundler's lifecycle
    module Hooks
      class << self
        # Install all hooks
        def install!
          install_dsl_extension
          install_dependency_extension
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
      end
    end
  end
end
