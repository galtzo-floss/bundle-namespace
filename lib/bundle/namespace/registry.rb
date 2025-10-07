# frozen_string_literal: true

module Bundle
  module Namespace
    # Registry to track namespace-to-source-to-gem mappings
    # This maintains the relationship between sources, namespaces, and gems
    class Registry
      class << self
        # Register a gem with its namespace and source
        #
        # @param source [String, Bundler::Source] The gem source
        # @param namespace [String, Symbol] The namespace identifier
        # @param gem_name [String] The name of the gem
        def register(source, namespace, gem_name)
          source_key = normalize_source(source)
          namespace_key = normalize_namespace(namespace)

          namespaces[source_key][namespace_key] << gem_name unless namespaces[source_key][namespace_key].include?(gem_name)
        end

        # Get all gems for a specific source and namespace
        #
        # @param source [String, Bundler::Source] The gem source
        # @param namespace [String, Symbol] The namespace identifier
        # @return [Array<String>] List of gem names
        def gems_for(source, namespace)
          source_key = normalize_source(source)
          namespace_key = normalize_namespace(namespace)

          namespaces[source_key][namespace_key]
        end

        # Get all namespaces for a specific source
        #
        # @param source [String, Bundler::Source] The gem source
        # @return [Array<String>] List of namespace identifiers
        def namespaces_for(source)
          source_key = normalize_source(source)
          namespaces[source_key].keys
        end

        # Check if a gem is registered in a namespace
        #
        # @param source [String, Bundler::Source] The gem source
        # @param namespace [String, Symbol] The namespace identifier
        # @param gem_name [String] The name of the gem
        # @return [Boolean]
        def registered?(source, namespace, gem_name)
          gems_for(source, namespace).include?(gem_name)
        end

        # Get the namespace for a gem (if uniquely registered)
        #
        # @param source [String, Bundler::Source] The gem source
        # @param gem_name [String] The name of the gem
        # @return [String, nil] The namespace or nil if not found/ambiguous
        def namespace_for(source, gem_name)
          source_key = normalize_source(source)
          found_namespaces = namespaces[source_key].select { |_ns, gems| gems.include?(gem_name) }.keys

          return if found_namespaces.empty?
          return found_namespaces.first if found_namespaces.size == 1

          # Multiple namespaces found - this is an error condition
          raise NamespaceConflictError.new(gem_name, found_namespaces.first, found_namespaces.last)
        end

        # Get all registered data (for lockfile generation)
        #
        # @return [Hash] Complete namespace registry
        def all
          namespaces
        end

        # Clear all registrations (useful for testing)
        def clear!
          @namespaces = nil
        end

        # Get count of registered gems
        #
        # @return [Integer]
        def size
          namespaces.values.sum { |ns_hash| ns_hash.values.sum(&:size) }
        end

        private

        # Internal storage: source_uri => namespace => [gem_names]
        def namespaces
          @namespaces ||= Hash.new do |h, source_key|
            h[source_key] = Hash.new { |h2, namespace_key| h2[namespace_key] = [] }
          end
        end

        # Normalize source to a consistent string key
        def normalize_source(source)
          case source
          when String
            source
          when nil
            "default"
          else
            # Assume it's a Bundler::Source object
            source.respond_to?(:to_s) ? source.to_s : source.inspect
          end
        end

        # Normalize namespace to a consistent string key
        def normalize_namespace(namespace)
          namespace.to_s
        end
      end
    end
  end
end
