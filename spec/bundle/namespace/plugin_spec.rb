# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bundle::Namespace::Plugin do
  describe ".install!" do
    it "installs the plugin successfully" do
      expect { described_class.install! }.not_to raise_error
    end

    it "marks plugin as installed" do
      described_class.install!
      expect(described_class.installed?).to be true
    end

    it "can be called multiple times safely" do
      described_class.install!
      expect { described_class.install! }.not_to raise_error
    end
  end

  describe ".installed?" do
    it "returns true after installation" do
      described_class.install!
      expect(described_class.installed?).to be true
    end
  end
end
