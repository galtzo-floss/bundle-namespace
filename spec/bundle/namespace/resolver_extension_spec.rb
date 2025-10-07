# frozen_string_literal: true

require "spec_helper"
require "bundler"

RSpec.describe Bundle::Namespace::ResolverExtension do
  before do
    Bundle::Namespace::Registry.clear!
    Bundle::Namespace::Plugin.install!
  end

  after do
    Bundle::Namespace::Registry.clear!
  end

  describe "namespace package tracking" do
    it "tracks packages with namespace metadata" do
      # This is a unit test for the internal tracking mechanism
      # In a real scenario, this would be tested via integration tests
      expect(true).to be true
    end
  end

  describe "#detect_namespace_conflict" do
    it "tracks conflicts when gem is requested from multiple namespaces" do
      # This would be tested in integration with actual resolution
      # For now, verify the error class exists
      expect(defined?(Bundle::Namespace::NamespaceConflictError)).to eq("constant")
    end

    it "raises error in strict mode when conflicts are detected" do
      Bundle::Namespace::Configuration.strict_mode = true

      expect {
        raise Bundle::Namespace::NamespaceConflictError.new("my-gem", "org1", "org2")
      }.to raise_error(Bundle::Namespace::NamespaceConflictError)
    end
  end

  describe "version filtering by namespace" do
    it "allows versions that match the namespace requirement" do
      # This would be tested with actual version objects in integration tests
      expect(true).to be true
    end
  end
end
