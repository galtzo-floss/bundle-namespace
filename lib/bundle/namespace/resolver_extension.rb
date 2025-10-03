# frozen_string_literal: true

module Bundle
  module Namespace
    # Extension to Bundler::Resolver to add namespace-aware resolution
    module ResolverExtension
      # Override setup_solver to include namespace awareness
      #
      # @return [Array] Root and logger for the solver
      def setup_solver
        root, logger = super

        # Enhance the solver with namespace awareness
        enhance_solver_with_namespaces

        [root, logger]
      end

      # Override all_versions_for to filter by namespace
      #
      # @param package [Object] The package to get versions for
      # @return [Array] Available versions
      def all_versions_for(package)
        versions = super

        # Filter versions based on namespace if applicable
        filter_versions_by_namespace(package, versions)
      end

      # Override package identification to include namespace
      #
      # @param dependency [Bundler::Dependency]
      # @return [Object] Package identifier
      def package_for_dependency(dependency)
        package = super

        # Attach namespace metadata to the package if present
        if dependency.respond_to?(:namespace) && dependency.namespace
          # Store namespace information for later use
          @namespace_packages ||= {}
          @namespace_packages[package] = dependency.namespace
        end

        package
      end

      private

      # Enhance the solver with namespace awareness
      def enhance_solver_with_namespaces
        # Track which packages belong to which namespaces
        @namespace_packages ||= {}

        # Initialize namespace conflict tracking
        @namespace_conflicts = []
      end

      # Filter versions based on namespace requirements
      #
      # @param package [Object] The package
      # @param versions [Array] Available versions
      # @return [Array] Filtered versions
      def filter_versions_by_namespace(package, versions)
        # Check if this package has a namespace requirement
        namespace = @namespace_packages&.dig(package)

        return versions unless namespace

        # Filter versions that match the namespace
        # In a real implementation, this would check if the version
        # is available in the specified namespace
        versions.select do |version|
          version_matches_namespace?(version, namespace)
        end
      end

      # Check if a version matches the required namespace
      #
      # @param version [Object] The version object
      # @param namespace [String] The required namespace
      # @return [Boolean]
      def version_matches_namespace?(version, namespace)
        # This would check if the version's source supports the namespace
        # For now, we assume all versions match (basic implementation)
        true
      end

      # Detect namespace conflicts during resolution
      #
      # @param gem_name [String] The gem name
      # @param namespaces [Array<String>] Conflicting namespaces
      def detect_namespace_conflict(gem_name, namespaces)
        return unless namespaces.size > 1

        @namespace_conflicts << {
          gem: gem_name,
          namespaces: namespaces
        }

        if Configuration.strict_mode?
          raise NamespaceConflictError.new(gem_name, namespaces.first, namespaces.last)
        elsif Configuration.warn_on_missing?
          Bundler.ui.warn "Warning: Gem '#{gem_name}' requested from multiple namespaces: #{namespaces.join(', ')}"
        end
      end

      # Get namespace conflicts found during resolution
      #
      # @return [Array<Hash>]
      def namespace_conflicts
        @namespace_conflicts ||= []
      end
    end
  end
end

