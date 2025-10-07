# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bundle::Namespace::BundlerIntegration do
  describe ".install!" do
    it "installs bundler integration hooks" do
      expect { described_class.install! }.not_to raise_error
    end

    it "can be called multiple times safely" do
      described_class.install!
      expect { described_class.install! }.not_to raise_error
    end
  end

  describe ".load_namespace_lockfile" do
    let(:temp_lockfile) { Tempfile.new(["namespace-lock", ".yaml"]) }

    before do
      Bundle::Namespace::Registry.clear!
      Bundle::Namespace::Configuration.lockfile_path = temp_lockfile.path
    end

    after do
      Bundle::Namespace::Registry.clear!
      Bundle::Namespace::Configuration.reset!
      temp_lockfile.close
      temp_lockfile.unlink
    end

    it "loads and populates registry from lockfile" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          myorg:
            my-gem:
              version: 1.0.0
              dependencies: []
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      described_class.send(:load_namespace_lockfile)

      expect(Bundle::Namespace::Registry.registered?("https://rubygems.org", "myorg", "my-gem")).to be true
    end

    it "handles missing lockfile gracefully" do
      Bundle::Namespace::Configuration.lockfile_path = "/nonexistent/lockfile.yaml"

      expect { described_class.send(:load_namespace_lockfile) }.not_to raise_error
    end

    it "handles invalid lockfile gracefully" do
      temp_lockfile.write("{ invalid yaml")
      temp_lockfile.close

      # Should not raise, just warn
      expect { described_class.send(:load_namespace_lockfile) }.not_to raise_error
    end
  end

  describe ".generate_namespace_lockfile" do
    let(:definition) { double("Definition") }

    before do
      Bundle::Namespace::Registry.clear!
    end

    after do
      Bundle::Namespace::Registry.clear!
    end

    it "generates lockfile when namespaces are registered" do
      Bundle::Namespace::Registry.register("https://rubygems.org", :myorg, "my-gem")

      generator = double("Generator")
      allow(generator).to receive(:needed?).and_return(true)
      allow(generator).to receive(:generate!).and_return(true)
      allow(generator).to receive(:lockfile_path).and_return("bundle-namespace-lock.yaml")

      allow(Bundle::Namespace::LockfileGenerator).to receive(:new).and_return(generator)

      expect { described_class.send(:generate_namespace_lockfile, definition) }.not_to raise_error
    end

    it "skips generation when no namespaces are registered" do
      expect(Bundle::Namespace::Registry.size).to eq(0)

      # Should not create generator
      expect(Bundle::Namespace::LockfileGenerator).not_to receive(:new)

      described_class.send(:generate_namespace_lockfile, definition)
    end
  end
end
