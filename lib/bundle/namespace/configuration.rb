# frozen_string_literal: true

module Bundle
  module Namespace
    # Configuration management for the namespace plugin
    class Configuration
      class << self
        # Whether to raise errors when namespace-aware sources don't support namespaces
        #
        # @return [Boolean]
        def strict_mode?
          return @strict_mode unless @strict_mode.nil?
          @strict_mode = bundler_config_value("namespace.strict_mode", false)
        end

        # Set strict mode
        #
        # @param value [Boolean]
        def strict_mode=(value)
          @strict_mode = value
        end

        # Whether to warn when namespaces are ignored by non-supporting sources
        #
        # @return [Boolean]
        def warn_on_missing?
          return @warn_on_missing unless @warn_on_missing.nil?
          @warn_on_missing = bundler_config_value("namespace.warn_on_missing", true)
        end

        # Set warn on missing
        #
        # @param value [Boolean]
        def warn_on_missing=(value)
          @warn_on_missing = value
        end

        # Custom path for namespace lockfile
        #
        # @return [String]
        def lockfile_path
          @lockfile_path ||= bundler_config_value("namespace.lockfile_path", "bundler-namespace-lock.yaml")
        end

        # Set lockfile path
        #
        # @param path [String]
        def lockfile_path=(path)
          @lockfile_path = path
        end

        # Reset all configuration to defaults
        def reset!
          @strict_mode = nil
          @warn_on_missing = nil
          @lockfile_path = nil
        end

        private

        # Get a configuration value from Bundler's settings
        #
        # @param key [String] The configuration key
        # @param default [Object] Default value if not set
        # @return [Object] The configuration value
        def bundler_config_value(key, default)
          return default unless defined?(Bundler)

          # Try to get from Bundler settings
          begin
            value = Bundler.settings[key]
            return default if value.nil?

            # Convert string booleans
            case value
            when "true", true
              true
            when "false", false
              false
            else
              value
            end
          rescue StandardError
            default
          end
        end
      end
    end
  end
end

