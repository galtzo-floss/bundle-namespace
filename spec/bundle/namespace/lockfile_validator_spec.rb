# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Bundle::Namespace::LockfileValidator do
  let(:parser) { Bundle::Namespace::LockfileParser.new }
  let(:validator) { described_class.new(parser) }
  let(:temp_lockfile) { Tempfile.new(["namespace-lock", ".yaml"]) }

  before do
    Bundle::Namespace::Registry.clear!
  end

  after do
    Bundle::Namespace::Registry.clear!
    temp_lockfile.close
    temp_lockfile.unlink
  end

  describe "#validate!" do
    it "returns true when lockfile doesn't exist" do
      allow(parser).to receive(:exists?).and_return(false)
      expect(validator.validate!).to be true
    end

    it "returns true for valid lockfile" do
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

      custom_parser = Bundle::Namespace::LockfileParser.new(temp_lockfile.path)
      custom_validator = described_class.new(custom_parser)

      expect(custom_validator.validate!).to be true
      expect(custom_validator.errors).to be_empty
    end

    it "returns false for invalid lockfile structure" do
      temp_lockfile.write("{ invalid yaml")
      temp_lockfile.close

      custom_parser = Bundle::Namespace::LockfileParser.new(temp_lockfile.path)
      custom_validator = described_class.new(custom_parser)

      expect(custom_validator.validate!).to be false
      expect(custom_validator.errors).not_to be_empty
    end

    it "returns false for missing version" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          myorg:
            my-gem:
              dependencies: []
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = Bundle::Namespace::LockfileParser.new(temp_lockfile.path)
      custom_validator = described_class.new(custom_parser)

      expect(custom_validator.validate!).to be false
      expect(custom_validator.errors).to include(/missing version/)
    end

    it "returns false for invalid version format" do
      lockfile_content = <<~YAML
        ---
        https://rubygems.org:
          myorg:
            my-gem:
              version: invalid.version.format
              dependencies: []
      YAML

      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = Bundle::Namespace::LockfileParser.new(temp_lockfile.path)
      custom_validator = described_class.new(custom_parser)

      expect(custom_validator.validate!).to be false
      expect(custom_validator.errors).to include(/Invalid version/)
    end
  end

  describe "#valid?" do
    it "returns validation result" do
      allow(parser).to receive(:exists?).and_return(false)
      expect(validator.valid?).to be true
    end
  end

  describe "#error_messages" do
    it "returns list of errors" do
      temp_lockfile.write("{ invalid")
      temp_lockfile.close

      custom_parser = Bundle::Namespace::LockfileParser.new(temp_lockfile.path)
      custom_validator = described_class.new(custom_parser)
      custom_validator.validate!

      expect(custom_validator.error_messages).not_to be_empty
    end
  end

  describe "#warning_messages" do
    it "warns when registered gem not in lockfile" do
      # Register a gem but have empty lockfile
      Bundle::Namespace::Registry.register("https://rubygems.org", :myorg, "my-gem")

      lockfile_content = "---\n{}"
      temp_lockfile.write(lockfile_content)
      temp_lockfile.close

      custom_parser = Bundle::Namespace::LockfileParser.new(temp_lockfile.path)
      custom_validator = described_class.new(custom_parser)
      custom_validator.validate!

      expect(custom_validator.warning_messages).to include(/not in lockfile/)
    end

    it "warns when lockfile gem not registered" do
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

      custom_parser = Bundle::Namespace::LockfileParser.new(temp_lockfile.path)
      custom_validator = described_class.new(custom_parser)
      custom_validator.validate!

      expect(custom_validator.warning_messages).to include(/not registered/)
    end
  end

  describe "#report" do
    it "reports errors and warnings" do
      ui = double("UI")
      allow(ui).to receive(:error)
      allow(ui).to receive(:warn)

      validator.instance_variable_set(:@errors, ["Error 1"])
      validator.instance_variable_set(:@warnings, ["Warning 1"])

      validator.report(ui)

      expect(ui).to have_received(:error).at_least(:once)
      expect(ui).to have_received(:warn).at_least(:once)
    end

    it "reports success when no errors or warnings" do
      ui = double("UI")
      allow(ui).to receive(:info)

      validator.instance_variable_set(:@errors, [])
      validator.instance_variable_set(:@warnings, [])

      validator.report(ui)

      expect(ui).to have_received(:info).with(/valid/)
    end
  end
end

