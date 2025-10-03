# frozen_string_literal: true

require_relative "registry"
require_relative "configuration"

module Bundle
  module Namespace
    # DSL extension to add namespace support to Bundler's Gemfile DSL
    # This module is prepended to Bundler::Dsl to add the namespace macro
    module DslExtension
      # Declare a namespace block for gems
      #
      # @example Block syntax
      #   namespace :myorg do
      #     gem 'my-gem'
      #   end
      #
      # @param namespaces [Array<Symbol, String>] One or more namespace identifiers
      # @yield Block containing gem declarations
      def namespace(*namespaces, &block)
        raise ArgumentError, "namespace requires a block" unless block_given?
        raise ArgumentError, "namespace requires at least one namespace identifier" if namespaces.empty?

        @namespaces ||= []
        @namespaces.concat(namespaces)

        begin
          yield
        ensure
          namespaces.each { @namespaces.pop }
        end
      end

      # Override gem method to support namespace option
      #
      # @example Option syntax
      #   gem 'my-gem', namespace: :myorg
      #
      # @param name [String] The gem name
      # @param args [Array] Version requirements and options
      def gem(name, *args)
        options = args.last.is_a?(Hash) ? args.last : {}

        # Support namespace as an option
        if options.key?(:namespace) || options.key?("namespace")
          namespace_value = options.delete(:namespace) || options.delete("namespace")

          # Temporarily set namespace for this gem
          @namespaces ||= []
          @namespaces.push(namespace_value)

          begin
            super(name, *args)
          ensure
            @namespaces.pop
          end
        else
          super(name, *args)
        end
      end

      private

      # Override add_dependency to include namespace metadata
      # This is called internally by the gem method
      def add_dependency(name, version = nil, options = {})
        # Add namespace to dependency options if currently in a namespace
        if defined?(@namespaces) && @namespaces&.any?
          current_namespace = @namespaces.last
          options["namespace"] = current_namespace.to_s

          # Register in the namespace registry
          source = options["source"] || @source
          Registry.register(source, current_namespace, name)
        end

        super(name, version, options)
      end
    end
  end
end
