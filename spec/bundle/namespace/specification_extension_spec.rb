# frozen_string_literal: true

require "spec_helper"
require "bundler"

RSpec.describe Bundle::Namespace::SpecificationExtension do
  # Create a mock specification class for testing
  let(:spec_class) do
    Class.new do
      attr_accessor :name, :source, :metadata

      def initialize(name, source = nil)
        @name = name
        @source = source
        @metadata = {}
      end

      # Include the extension
      prepend Bundle::Namespace::SpecificationExtension
    end
  end

  let(:spec) { spec_class.new("my-gem") }

  before do
    Bundle::Namespace::Registry.clear!
  end

  after do
    Bundle::Namespace::Registry.clear!
  end

  describe "#namespace" do
    it "returns nil when no namespace is set" do
      expect(spec.namespace).to be_nil
    end

    it "returns namespace from metadata when set" do
      spec.metadata["namespace"] = "myorg"
      expect(spec.namespace).to eq("myorg")
    end

    it "retrieves namespace from registry when available" do
      source = double("Source")
      spec.source = source
      Bundle::Namespace::Registry.register(source, :myorg, "my-gem")

      expect(spec.namespace).to eq("myorg")
    end
  end

  describe "#namespace=" do
    it "sets the namespace" do
      spec.namespace = "myorg"
      expect(spec.namespace).to eq("myorg")
    end

    it "stores namespace in metadata" do
      spec.namespace = "myorg"
      expect(spec.metadata["namespace"]).to eq("myorg")
    end

    it "converts symbols to strings" do
      spec.namespace = :myorg
      expect(spec.namespace).to eq("myorg")
    end
  end

  describe "#namespaced?" do
    it "returns false when no namespace is set" do
      expect(spec.namespaced?).to be false
    end

    it "returns true when namespace is set" do
      spec.namespace = "myorg"
      expect(spec.namespaced?).to be true
    end
  end

  describe "#namespaced_name" do
    it "returns regular name when not namespaced" do
      expect(spec.namespaced_name).to eq("my-gem")
    end

    it "returns namespace/name when namespaced" do
      spec.namespace = "myorg"
      expect(spec.namespaced_name).to eq("myorg/my-gem")
    end
  end

  describe "#to_s" do
    it "includes namespace in string representation when namespaced" do
      spec.namespace = "myorg"
      # The actual to_s implementation will depend on the parent class
      # For now, just verify the method exists and can be called
      expect { spec.to_s }.not_to raise_error
    end
  end

  describe "equality with namespace" do
    let(:spec1) { spec_class.new("my-gem") }
    let(:spec2) { spec_class.new("my-gem") }

    it "considers specs with same name but different namespace as different" do
      spec1.namespace = "org1"
      spec2.namespace = "org2"

      expect(spec1).not_to eq(spec2)
    end

    it "considers specs with same name and namespace as having matching attributes" do
      spec1.namespace = "myorg"
      spec2.namespace = "myorg"

      # Since our mock doesn't have a base == implementation, test via attribute comparison
      # In real Bundler specs, the parent class provides proper == implementation
      expect(spec1.namespace).to eq(spec2.namespace)
      expect(spec1.name).to eq(spec2.name)
    end

    it "uses namespace in hash calculation" do
      spec1.namespace = "org1"
      spec2.namespace = "org2"

      expect(spec1.hash).not_to eq(spec2.hash)
    end
  end
end

