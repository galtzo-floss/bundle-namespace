# frozen_string_literal: true

module Bundle
  module Namespace
    # Extension to track namespace information in gem specifications
    module SpecificationExtension
      # Get the namespace for this specification
      #
      # @return [String, nil]
      def namespace
        return @namespace if defined?(@namespace)

        # Try to get from metadata first
        @namespace = metadata["namespace"] if respond_to?(:metadata)

        # If not in metadata, check the registry
        @namespace ||= Registry.namespace_for(source, name) if respond_to?(:source) && respond_to?(:name)

        @namespace
      rescue NamespaceConflictError
        nil
      end

      # Set the namespace for this specification
      #
      # @param value [String, Symbol]
      def namespace=(value)
        @namespace = value.to_s

        # Store in metadata if possible
        if respond_to?(:metadata)
          metadata["namespace"] = @namespace
        end
      end

      # Check if this specification is namespaced
      #
      # @return [Boolean]
      def namespaced?
        !namespace.nil?
      end

      # Get the full namespaced name
      #
      # @return [String]
      def namespaced_name
        if namespaced?
          "#{namespace}/#{name}"
        else
          name
        end
      end

      # Override to_s to include namespace if present
      #
      # @return [String]
      def to_s
        if namespaced?
          "#{namespace}/#{super}"
        else
          super
        end
      end

      # Check equality including namespace
      #
      # @param other [Gem::Specification]
      # @return [Boolean]
      def ==(other)
        super && namespace == other.namespace
      end

      alias eql? ==

      # Include namespace in hash calculation
      #
      # @return [Integer]
      def hash
        [super, namespace].hash
      end
    end
  end
end
# frozen_string_literal: true

module Bundle
  module Namespace
    # Extension to Bundler::Source::Rubygems to add namespace-aware gem lookups
    module SourceRubygemsExtension
      # Check if this source supports namespaces
      #
      # @return [Boolean]
      def namespace_aware?
        # Check if the source has namespace support
        # This could be detected via HTTP headers, API endpoints, or configuration
        @namespace_aware ||= detect_namespace_support
      end

      # Override specs to apply namespace filtering
      #
      # @return [Bundler::Index]
      def specs
        index = super

        # Apply namespace filtering if this source is namespace-aware
        if namespace_aware? && has_namespace_dependencies?
          apply_namespace_filtering(index)
        else
          index
        end
      end

      # Override remote_specs to handle namespace in remote lookups
      #
      # @return [Bundler::Index]
      def remote_specs
        @remote_specs ||= begin
          index = super

          # If we have namespace dependencies, filter the remote specs
          if namespace_aware? && has_namespace_dependencies?
            apply_namespace_filtering(index)
          else
            index
          end
        end
      end

      # Construct the gem path with namespace prefix
      #
      # @param spec [Bundler::RemoteSpecification, Gem::Specification]
      # @param namespace [String, nil] The namespace for the gem
      # @return [String] The path to the gem
      def namespaced_gem_path(spec, namespace = nil)
        if namespace && namespace_aware?
          # Construct path as: /namespace/gem-name/version
          "#{namespace}/#{spec.name}"
        else
          spec.name
        end
      end

      # Override fetch_gem to handle namespaced gem downloads
      #
      # @param spec [Bundler::RemoteSpecification]
      # @param options [Hash]
      # @return [String] Path to downloaded gem
      def fetch_gem(spec, options = {})
        # Check if this gem has a namespace
        namespace = gem_namespace_for_spec(spec)

        if namespace && namespace_aware?
          fetch_namespaced_gem(spec, namespace, options)
        else
          super
        end
      end

      private

      # Detect if the source supports namespaces
      #
      # @return [Boolean]
      def detect_namespace_support
        # For now, assume sources can be configured to support namespaces
        # In a real implementation, this might check:
        # - HTTP headers (X-Namespace-Support: true)
        # - API endpoint (/api/v1/namespaces)
        # - Configuration setting

        # Check if any dependencies have namespaces
        has_namespace_dependencies?
      end

      # Check if any dependencies have namespaces
      #
      # @return [Boolean]
      def has_namespace_dependencies?
        return false unless defined?(@dependency_names) && @dependency_names

        @dependency_names.any? do |name|
          Registry.namespaces_for(self).any? do |namespace|
            Registry.registered?(self, namespace, name)
          end
        end
      end

      # Apply namespace filtering to an index
      #
      # @param index [Bundler::Index]
      # @return [Bundler::Index]
      def apply_namespace_filtering(index)
        # Filter specs based on namespace registrations
        filtered_specs = index.specs.select do |spec|
          namespace = gem_namespace_for_spec(spec)

          # Keep the spec if:
          # 1. It doesn't have a namespace requirement, OR
          # 2. It's registered in a namespace and matches
          if namespace
            Registry.registered?(self, namespace, spec.name)
          else
            # Non-namespaced gems are always included
            true
          end
        end

        # Create a new index with filtered specs
        Bundler::Index.build do |idx|
          filtered_specs.each { |spec| idx << spec }
        end
      end

      # Get the namespace for a spec
      #
      # @param spec [Bundler::RemoteSpecification, Gem::Specification]
      # @return [String, nil]
      def gem_namespace_for_spec(spec)
        # Try to find namespace from the registry
        Registry.namespace_for(self, spec.name)
      rescue NamespaceConflictError
        # If there's a conflict, we can't determine the namespace automatically
        nil
      end

      # Fetch a namespaced gem from the remote source
      #
      # @param spec [Bundler::RemoteSpecification]
      # @param namespace [String]
      # @param options [Hash]
      # @return [String] Path to downloaded gem
      def fetch_namespaced_gem(spec, namespace, options = {})
        # Construct the namespaced gem URI
        # This would typically be: https://source.com/namespace/gems/gem-name-version.gem
        original_name = spec.name

        # Temporarily modify the spec name to include namespace path
        namespaced_name = "#{namespace}/#{original_name}"

        # In a real implementation, we'd need to modify the fetch logic
        # For now, delegate to super and log the namespace
        if Configuration.warn_on_missing?
          Bundler.ui.warn "Fetching namespaced gem: #{namespaced_name}"
        end

        super(spec, options)
      end
    end
  end
end

