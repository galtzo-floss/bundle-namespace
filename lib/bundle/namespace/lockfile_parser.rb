# frozen_string_literal: true

require "yaml"

module Bundle
  module Namespace
    # Parses the bundle-namespace-lock.yaml file
    class LockfileParser
      attr_reader :lockfile_path, :data

      # Initialize the parser
      #
      # @param lockfile_path [String, nil] Path to the lockfile
      def initialize(lockfile_path = nil)
        @lockfile_path = lockfile_path || Configuration.lockfile_path
        @data = nil
      end

      # Parse the lockfile
      #
      # @return [Hash] The parsed lockfile data
      # @raise [InvalidNamespaceLockfileError] if lockfile is invalid
      def parse
        unless File.exist?(lockfile_path)
          return {}
        end

        content = File.read(lockfile_path)
        @data = YAML.safe_load(content, permitted_classes: [Symbol]) || {}

        validate_structure!

        @data
      rescue Psych::SyntaxError => e
        raise InvalidNamespaceLockfileError, "YAML syntax error: #{e.message}"
      rescue StandardError => e
        raise InvalidNamespaceLockfileError, "Failed to parse lockfile: #{e.message}"
      end

      # Check if lockfile exists
      #
      # @return [Boolean]
      def exists?
        File.exist?(lockfile_path)
      end

      # Get all sources from the lockfile
      #
      # @return [Array<String>]
      def sources
        parse unless @data
        @data.keys
      end

      # Get all namespaces for a source
      #
      # @param source [String] The source URL
      # @return [Array<String>]
      def namespaces_for(source)
        parse unless @data
        @data.dig(source)&.keys || []
      end

      # Get all gems in a namespace
      #
      # @param source [String] The source URL
      # @param namespace [String] The namespace
      # @return [Hash] Gem name => gem data
      def gems_for(source, namespace)
        parse unless @data
        @data.dig(source, namespace) || {}
      end

      # Get data for a specific gem
      #
      # @param source [String] The source URL
      # @param namespace [String] The namespace
      # @param gem_name [String] The gem name
      # @return [Hash, nil] Gem data
      def gem_data(source, namespace, gem_name)
        parse unless @data
        @data.dig(source, namespace, gem_name)
      end

      # Get version for a specific gem
      #
      # @param source [String] The source URL
      # @param namespace [String] The namespace
      # @param gem_name [String] The gem name
      # @return [String, nil] Version string
      def gem_version(source, namespace, gem_name)
        gem_data(source, namespace, gem_name)&.dig("version")
      end

      # Populate the registry from the lockfile
      #
      # @return [Boolean] True if successful
      def populate_registry!
        parse unless @data

        @data.each do |source, namespaces|
          namespaces.each do |namespace, gems|
            gems.keys.each do |gem_name|
              Registry.register(source, namespace, gem_name)
            end
          end
        end

        true
      end

      private

      # Validate the lockfile structure
      #
      # @raise [InvalidNamespaceLockfileError] if structure is invalid
      def validate_structure!
        unless @data.is_a?(Hash)
          raise InvalidNamespaceLockfileError, "Lockfile must be a hash at the top level"
        end

        @data.each do |source, namespaces|
          unless namespaces.is_a?(Hash)
            raise InvalidNamespaceLockfileError, "Namespaces for source '#{source}' must be a hash"
          end

          namespaces.each do |namespace, gems|
            unless gems.is_a?(Hash)
              raise InvalidNamespaceLockfileError, "Gems for namespace '#{namespace}' must be a hash"
            end

            validate_gem_data!(gems, source, namespace)
          end
        end
      end

      # Validate gem data structure
      #
      # @param gems [Hash] The gems hash
      # @param source [String] The source URL
      # @param namespace [String] The namespace
      # @raise [InvalidNamespaceLockfileError] if gem data is invalid
      def validate_gem_data!(gems, source, namespace)
        gems.each do |gem_name, gem_data|
          unless gem_data.is_a?(Hash)
            raise InvalidNamespaceLockfileError,
              "Data for gem '#{gem_name}' in #{source}/#{namespace} must be a hash"
          end

          # Validate required fields
          unless gem_data.key?("version")
            raise InvalidNamespaceLockfileError,
              "Gem '#{gem_name}' in #{source}/#{namespace} missing version"
          end
        end
      end
    end
  end
end
