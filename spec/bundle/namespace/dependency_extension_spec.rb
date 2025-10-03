# frozen_string_literal: true

require "spec_helper"
require "bundler"
require "bundler/dependency"

RSpec.describe Bundle::Namespace::DependencyExtension do
  before do
    # Ensure the extension is loaded
    Bundle::Namespace::Plugin.install!
  end

  describe "#namespace" do
    it "returns namespace from options" do
      dep = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "myorg")
      expect(dep.namespace).to eq("myorg")
    end

    it "returns nil when no namespace is set" do
      dep = Bundler::Dependency.new("my-gem", ">= 0")
      expect(dep.namespace).to be_nil
    end
  end

  describe "#namespaced?" do
    it "returns true when namespace is set" do
      dep = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "myorg")
      expect(dep.namespaced?).to be true
    end

    it "returns false when namespace is not set" do
      dep = Bundler::Dependency.new("my-gem", ">= 0")
      expect(dep.namespaced?).to be false
    end
  end

  describe "#to_s" do
    it "includes namespace in string representation" do
      dep = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "myorg")
      expect(dep.to_s).to include("myorg")
      expect(dep.to_s).to include("my-gem")
    end

    it "works normally without namespace" do
      dep = Bundler::Dependency.new("my-gem", ">= 0")
      string = dep.to_s
      expect(string).to include("my-gem")
      expect(string).not_to include("/")
    end
  end

  describe "#==" do
    it "considers namespace in equality" do
      dep1 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org1")
      dep2 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org2")
      dep3 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org1")

      expect(dep1).not_to eq(dep2)
      expect(dep1).to eq(dep3)
    end

    it "treats nil namespace as different from set namespace" do
      dep1 = Bundler::Dependency.new("my-gem", ">= 0")
      dep2 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org1")

      expect(dep1).not_to eq(dep2)
    end
  end

  describe "#hash" do
    it "includes namespace in hash calculation" do
      dep1 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org1")
      dep2 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org2")
      dep3 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org1")

      expect(dep1.hash).not_to eq(dep2.hash)
      expect(dep1.hash).to eq(dep3.hash)
    end
  end

  describe "#eql?" do
    it "works the same as ==" do
      dep1 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org1")
      dep2 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org2")
      dep3 = Bundler::Dependency.new("my-gem", ">= 0", "namespace" => "org1")

      expect(dep1.eql?(dep2)).to be false
      expect(dep1.eql?(dep3)).to be true
    end
  end
end

