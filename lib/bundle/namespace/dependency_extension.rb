# frozen_string_literal: true

module Bundle
  module Namespace
    # Extension to Bundler::Dependency to add namespace awareness
    module DependencyExtension
      # Get the namespace for this dependency
      #
      # @return [String, nil] The namespace or nil if not namespaced
      def namespace
        return @namespace if defined?(@namespace)

        @namespace = @options["namespace"]
      end

      # Check if this dependency is namespaced
      #
      # @return [Boolean]
      def namespaced?
        !namespace.nil?
      end

      # Override to_s to include namespace information
      #
      # @return [String]
      def to_s
        if namespaced?
          "#{namespace}/#{super}"
        else
          super
        end
      end

      # Override to_lock to include namespace in lockfile representation
      # Note: This maintains compatibility - namespace goes in separate lockfile
      #
      # @return [String]
      def to_lock
        super
      end

      # Check equality including namespace
      #
      # @param other [Bundler::Dependency]
      # @return [Boolean]
      def ==(other)
        super && namespace == other.namespace
      end

      # Hash code including namespace
      #
      # @return [Integer]
      def hash
        [super, namespace].hash
      end

      alias eql? ==
    end
  end
end

