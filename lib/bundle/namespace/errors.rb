# frozen_string_literal: true

module Bundle
  module Namespace
    # Base error class for all namespace-related errors
    class Error < StandardError; end

    # Raised when a gem is specified in multiple conflicting namespaces
    class NamespaceConflictError < Error
      def initialize(gem_name, namespace1, namespace2)
        super("Gem '#{gem_name}' specified in multiple namespaces: " \
              "#{namespace1} and #{namespace2}")
      end
    end

    # Raised when a source doesn't support namespaces but namespaces are required
    class NamespaceNotSupportedError < Error
      def initialize(source)
        super("Source '#{source}' does not support namespaces. " \
              "Please use a namespace-aware gem server or disable strict mode.")
      end
    end

    # Raised when namespace lockfile is invalid or corrupted
    class InvalidNamespaceLockfileError < Error
      def initialize(message = "Invalid or corrupted namespace lockfile")
        super(message)
      end
    end

    # Raised when there's an inconsistency between lockfiles
    class LockfileInconsistencyError < Error
      def initialize(gem_name, details)
        super("Lockfile inconsistency for gem '#{gem_name}': #{details}")
      end
    end
  end
end

