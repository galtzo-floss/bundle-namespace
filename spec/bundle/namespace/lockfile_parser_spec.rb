# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Bundle::Namespace::LockfileParser do
  let(:parser) { described_class.new }
  let(:temp_lockfile) { Tempfile.new(["namespace-lock", ".yaml"]) }

  before do
    Bundle::Namespace::Registry.clear!
  end

  after do
    Bundle::Namespace::Registry.clear!
    temp_lockfile.close
    temp_lockfile.unlink
  end

  describe "#exists?" do
    it "returns false when lockfile doesn't exist" do
      custom_parser = described_class.new("/nonexistent/lockfile.yaml")
      expect(custom_parser.exists?).to be false
    end

    it "returns true when lockfile exists" do
      temp_lockfile.write("---\n{}")
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)
      expect(custom_parser.exists?).to be true
    end
  end

  describe "#parse" do
    it "returns empty hash when lockfile doesn't exist" do
      custom_parser = described_class.new("/nonexistent/lockfile.yaml")
      expect(custom_parser.parse).to eq({})
    end

    it "parses valid lockfile structure" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          myorg:
            my-gem:
              version: 1.2.3
              dependencies: []
              platform: ruby
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)
      data = custom_parser.parse

      expect(data).to have_key("https://rubygems.org")
      expect(data["https://rubygems.org"]).to have_key("myorg")
    end

    it "raises error for invalid YAML" do
      temp_lockfile.write("{ invalid: yaml: syntax")
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)

      expect {
        custom_parser.parse
      }.to raise_error(Bundle::Namespace::InvalidNamespaceLockfileError, /YAML syntax error/)
    end

    it "raises error for invalid structure (non-hash top level)" do
      temp_lockfile.write("---\n- invalid\n- structure")
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)

      expect {
        custom_parser.parse
      }.to raise_error(Bundle::Namespace::InvalidNamespaceLockfileError, /must be a hash/)
    end
  end

  describe "#sources" do
    it "returns list of sources from lockfile" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          myorg:
            gem1:
              version: 1.0.0
        https://gems.example.com:
          otherorg:
            gem2:
              version: 2.0.0
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)
      sources = custom_parser.sources

      expect(sources).to contain_exactly("https://rubygems.org", "https://gems.example.com")
    end
  end

  describe "#namespaces_for" do
    it "returns namespaces for a given source" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          org1:
            gem1:
              version: 1.0.0
          org2:
            gem2:
              version: 2.0.0
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)
      namespaces = custom_parser.namespaces_for("https://rubygems.org")

      expect(namespaces).to contain_exactly("org1", "org2")
    end
  end

  describe "#gems_for" do
    it "returns gems for a given source and namespace" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          myorg:
            gem1:
              version: 1.0.0
            gem2:
              version: 2.0.0
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)
      gems = custom_parser.gems_for("https://rubygems.org", "myorg")

      expect(gems.keys).to contain_exactly("gem1", "gem2")
    end
  end

  describe "#gem_data" do
    it "returns data for a specific gem" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          myorg:
            my-gem:
              version: 1.2.3
              dependencies:
                - rails
                - rspec
              platform: ruby
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)
      gem_data = custom_parser.gem_data("https://rubygems.org", "myorg", "my-gem")

      expect(gem_data["version"]).to eq("1.2.3")
      expect(gem_data["dependencies"]).to contain_exactly("rails", "rspec")
    end
  end

  describe "#gem_version" do
    it "returns version for a specific gem" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          myorg:
            my-gem:
              version: 1.2.3
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)
      version = custom_parser.gem_version("https://rubygems.org", "myorg", "my-gem")

      expect(version).to eq("1.2.3")
    end
  end

  describe "#populate_registry!" do
    it "populates the registry from lockfile" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          myorg:
            gem1:
              version: 1.0.0
            gem2:
              version: 2.0.0
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = described_class.new(temp_lockfile.path)
      result = custom_parser.populate_registry!

      expect(result).to be true
      expect(Bundle::Namespace::Registry.registered?("https://rubygems.org", "myorg", "gem1")).to be true
      expect(Bundle::Namespace::Registry.registered?("https://rubygems.org", "myorg", "gem2")).to be true
    end
  end
end

