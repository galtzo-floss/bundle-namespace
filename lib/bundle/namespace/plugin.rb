# frozen_string_literal: true

require_relative "hooks"
require_relative "errors"
require_relative "registry"
require_relative "configuration"

module Bundle
  module Namespace
    # Main plugin class for Bundler integration
    class Plugin
      class << self
        # Install the plugin
        def install!
          return if @installed

          # Only install if bundler is available
          return unless bundler_available?

          require_bundler
          Hooks.install!

          @installed = true
        end

        # Check if plugin is installed
        #
        # @return [Boolean]
        def installed?
          @installed ||= false
        end

        private

        # Check if bundler is available
        def bundler_available?
          defined?(Bundler)
        end

        # Require bundler if not already loaded
        def require_bundler
          require "bundler" unless defined?(Bundler)
          require "bundler/dependency" unless defined?(Bundler::Dependency)
          require "bundler/dsl" unless defined?(Bundler::Dsl)
        rescue LoadError
          # Bundler not available, skip installation
          false
        end
      end
    end
  end
end

# Auto-install the plugin when this file is required (if bundler is available)
Bundle::Namespace::Plugin.install!
