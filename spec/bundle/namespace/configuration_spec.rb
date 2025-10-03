# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bundle::Namespace::Configuration do
  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  describe ".strict_mode?" do
    it "defaults to false" do
      expect(described_class.strict_mode?).to be false
    end

    it "can be set to true" do
      described_class.strict_mode = true
      expect(described_class.strict_mode?).to be true
    end

    it "can be set to false" do
      described_class.strict_mode = false
      expect(described_class.strict_mode?).to be false
    end
  end

  describe ".warn_on_missing?" do
    it "defaults to true" do
      expect(described_class.warn_on_missing?).to be true
    end

    it "can be set to false" do
      described_class.warn_on_missing = false
      expect(described_class.warn_on_missing?).to be false
    end

    it "can be set to true" do
      described_class.warn_on_missing = true
      expect(described_class.warn_on_missing?).to be true
    end
  end

  describe ".lockfile_path" do
    it "defaults to bundler-namespace-lock.yaml" do
      expect(described_class.lockfile_path).to eq("bundler-namespace-lock.yaml")
    end

    it "can be set to a custom path" do
      described_class.lockfile_path = "custom-namespace.yaml"
      expect(described_class.lockfile_path).to eq("custom-namespace.yaml")
    end
  end

  describe ".reset!" do
    it "resets all configuration to defaults" do
      described_class.strict_mode = true
      described_class.warn_on_missing = false
      described_class.lockfile_path = "custom.yaml"

      described_class.reset!

      expect(described_class.strict_mode?).to be false
      expect(described_class.warn_on_missing?).to be true
      expect(described_class.lockfile_path).to eq("bundler-namespace-lock.yaml")
    end
  end
end

