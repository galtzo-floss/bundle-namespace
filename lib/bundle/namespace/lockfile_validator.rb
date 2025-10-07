# frozen_string_literal: true

module Bundle
  module Namespace
    # Validates consistency between Gemfile, Gemfile.lock, and namespace lockfile
    class LockfileValidator
      attr_reader :parser, :errors, :warnings

      # Initialize the validator
      #
      # @param parser [LockfileParser] The lockfile parser
      def initialize(parser = nil)
        @parser = parser || LockfileParser.new
        @errors = []
        @warnings = []
      end

      # Validate the lockfile
      #
      # @return [Boolean] True if valid
      def validate!
        @errors = []
        @warnings = []

        return true unless @parser.exists?

        validate_structure
        validate_against_registry
        validate_gem_versions

        @errors.empty?
      end

      # Check if lockfile is valid
      #
      # @return [Boolean]
      def valid?
        validate!
      end

      # Get validation errors
      #
      # @return [Array<String>]
      def error_messages
        @errors
      end

      # Get validation warnings
      #
      # @return [Array<String>]
      def warning_messages
        @warnings
      end

      # Report validation results
      #
      # @param ui [Bundler::UI] The UI object for output
      def report(ui = nil)
        ui ||= Bundler.ui if defined?(Bundler)
        return unless ui

        if @errors.any?
          ui.error("Namespace lockfile validation errors:")
          @errors.each { |error| ui.error("  - #{error}") }
        end

        if @warnings.any?
          ui.warn("Namespace lockfile validation warnings:")
          @warnings.each { |warning| ui.warn("  - #{warning}") }
        end

        if @errors.empty? && @warnings.empty?
          ui.info("Namespace lockfile is valid")
        end
      end

      private

      # Validate basic lockfile structure
      def validate_structure
        @parser.parse
      rescue InvalidNamespaceLockfileError => e
        @errors << "Invalid lockfile structure: #{e.message}"
      end

      # Validate lockfile against current registry
      def validate_against_registry
        return unless @parser.data

        # Check if all registered gems are in the lockfile
        Registry.all.each do |source, namespaces|
          namespaces.each do |namespace, gem_names|
            gem_names.each do |gem_name|
              unless @parser.gem_data(source, namespace, gem_name)
                @warnings << "Gem '#{gem_name}' registered in namespace '#{namespace}' but not in lockfile"
              end
            end
          end
        end

        # Check if all lockfile gems are still registered
        @parser.sources.each do |source|
          @parser.namespaces_for(source).each do |namespace|
            @parser.gems_for(source, namespace).keys.each do |gem_name|
              unless Registry.registered?(source, namespace, gem_name)
                @warnings << "Gem '#{gem_name}' in lockfile but not registered in namespace '#{namespace}'"
              end
            end
          end
        end
      end

      # Validate gem versions in lockfile
      def validate_gem_versions
        return unless @parser.data

        @parser.sources.each do |source|
          @parser.namespaces_for(source).each do |namespace|
            @parser.gems_for(source, namespace).each do |gem_name, gem_data|
              validate_gem_version(source, namespace, gem_name, gem_data)
            end
          end
        end
      end

      # Validate a specific gem's version
      #
      # @param source [String]
      # @param namespace [String]
      # @param gem_name [String]
      # @param gem_data [Hash]
      def validate_gem_version(source, namespace, gem_name, gem_data)
        version = gem_data["version"]

        unless version
          @errors << "Gem '#{gem_name}' in #{namespace} missing version"
          return
        end

        # Validate version format
        begin
          Gem::Version.new(version)
        rescue ArgumentError
          @errors << "Invalid version '#{version}' for gem '#{gem_name}' in #{namespace}"
        end
      end
    end
  end
end
# frozen_string_literal: true

require "yaml"

module Bundle
  module Namespace
    # Generates the bundle-namespace-lock.yaml file
    class LockfileGenerator
      attr_reader :definition, :lockfile_path

      # Initialize the generator
      #
      # @param definition [Bundler::Definition] The bundle definition
      # @param lockfile_path [String, nil] Custom path for the lockfile
      def initialize(definition, lockfile_path = nil)
        @definition = definition
        @lockfile_path = lockfile_path || Configuration.lockfile_path
      end

      # Generate the namespace lockfile
      #
      # @return [String] The YAML content
      def generate
        lockfile_data = build_lockfile_structure
        YAML.dump(lockfile_data)
      end

      # Generate and write the lockfile to disk
      #
      # @return [Boolean] True if written successfully
      def generate!
        content = generate

        # Write to the lockfile path
        File.write(lockfile_path, content)

        true
      rescue StandardError => e
        Bundler.ui.warn("Failed to write namespace lockfile: #{e.message}") if defined?(Bundler)
        false
      end

      # Check if lockfile generation is needed
      #
      # @return [Boolean]
      def needed?
        # Only generate if we have namespaced dependencies
        Registry.size > 0
      end

      private

      # Build the three-level lockfile structure: source -> namespace -> gems
      #
      # @return [Hash]
      def build_lockfile_structure
        structure = {}

        # Iterate through all registered namespaces
        Registry.all.each do |source_key, namespaces|
          # Use source URL as key (quoted for YAML)
          source_url = normalize_source_url(source_key)
          structure[source_url] = {}

          namespaces.each do |namespace, gem_names|
            structure[source_url][namespace] = {}

            gem_names.each do |gem_name|
              gem_data = build_gem_data(gem_name, source_key)
              structure[source_url][namespace][gem_name] = gem_data if gem_data
            end
          end
        end

        structure
      end

      # Build data for a specific gem
      #
      # @param gem_name [String] The gem name
      # @param source_key [String] The source identifier
      # @return [Hash, nil]
      def build_gem_data(gem_name, source_key)
        # Try to find the gem in the resolved specs
        spec = find_spec_for_gem(gem_name)

        return unless spec

        {
          "version" => spec.version.to_s,
          "dependencies" => extract_dependencies(spec),
          "platform" => spec.platform.to_s,
        }
      end

      # Find the spec for a gem in the definition
      #
      # @param gem_name [String]
      # @return [Gem::Specification, nil]
      def find_spec_for_gem(gem_name)
        return unless defined?(@definition) && @definition

        # Try to find in resolved specs
        if @definition.respond_to?(:resolve)
          @definition.resolve.find { |spec| spec.name == gem_name }
        elsif @definition.respond_to?(:specs)
          @definition.specs.find { |spec| spec.name == gem_name }
        end
      rescue StandardError
        nil
      end

      # Extract dependency names from a spec
      #
      # @param spec [Gem::Specification]
      # @return [Array<String>]
      def extract_dependencies(spec)
        return [] unless spec.respond_to?(:dependencies)

        spec.dependencies.map(&:name).sort
      rescue StandardError
        []
      end

      # Normalize source URL for use as YAML key
      #
      # @param source_key [String]
      # @return [String]
      def normalize_source_url(source_key)
        # Ensure proper quoting for URLs in YAML
        source_key.to_s
      end
    end
  end
end
