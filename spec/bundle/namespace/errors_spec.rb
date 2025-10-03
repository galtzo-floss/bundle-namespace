# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bundle::Namespace::NamespaceConflictError do
  it "has a descriptive message" do
    error = described_class.new("my-gem", "org1", "org2")
    expect(error.message).to include("my-gem")
    expect(error.message).to include("org1")
    expect(error.message).to include("org2")
    expect(error.message).to include("multiple namespaces")
  end
end

RSpec.describe Bundle::Namespace::NamespaceNotSupportedError do
  it "has a descriptive message" do
    error = described_class.new("https://example.com")
    expect(error.message).to include("https://example.com")
    expect(error.message).to include("does not support namespaces")
  end
end

RSpec.describe Bundle::Namespace::InvalidNamespaceLockfileError do
  it "has a default message" do
    error = described_class.new
    expect(error.message).to include("Invalid")
    expect(error.message).to include("lockfile")
  end

  it "accepts a custom message" do
    error = described_class.new("Custom error message")
    expect(error.message).to eq("Custom error message")
  end
end

RSpec.describe Bundle::Namespace::LockfileInconsistencyError do
  it "has a descriptive message" do
    error = described_class.new("my-gem", "version mismatch")
    expect(error.message).to include("my-gem")
    expect(error.message).to include("version mismatch")
    expect(error.message).to include("inconsistency")
  end
end
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bundle::Namespace::Registry do
  before do
    described_class.clear!
  end

  after do
    described_class.clear!
  end

  describe ".register" do
    it "registers a gem with a source and namespace" do
      described_class.register("https://rubygems.org", :myorg, "my-gem")

      expect(described_class.gems_for("https://rubygems.org", :myorg)).to include("my-gem")
    end

    it "handles multiple gems in the same namespace" do
      described_class.register("https://rubygems.org", :myorg, "gem1")
      described_class.register("https://rubygems.org", :myorg, "gem2")

      gems = described_class.gems_for("https://rubygems.org", :myorg)
      expect(gems).to contain_exactly("gem1", "gem2")
    end

    it "handles multiple namespaces for the same source" do
      described_class.register("https://rubygems.org", :org1, "gem1")
      described_class.register("https://rubygems.org", :org2, "gem2")

      expect(described_class.gems_for("https://rubygems.org", :org1)).to eq(["gem1"])
      expect(described_class.gems_for("https://rubygems.org", :org2)).to eq(["gem2"])
    end

    it "does not duplicate gems in the same namespace" do
      described_class.register("https://rubygems.org", :myorg, "my-gem")
      described_class.register("https://rubygems.org", :myorg, "my-gem")

      expect(described_class.gems_for("https://rubygems.org", :myorg)).to eq(["my-gem"])
    end

    it "normalizes namespace symbols and strings" do
      described_class.register("https://rubygems.org", :myorg, "gem1")
      described_class.register("https://rubygems.org", "myorg", "gem2")

      gems = described_class.gems_for("https://rubygems.org", :myorg)
      expect(gems).to contain_exactly("gem1", "gem2")
    end
  end

  describe ".gems_for" do
    it "returns empty array for unregistered namespace" do
      expect(described_class.gems_for("https://rubygems.org", :unknown)).to eq([])
    end

    it "returns registered gems for a namespace" do
      described_class.register("https://rubygems.org", :myorg, "gem1")
      described_class.register("https://rubygems.org", :myorg, "gem2")

      expect(described_class.gems_for("https://rubygems.org", :myorg)).to contain_exactly("gem1", "gem2")
    end
  end

  describe ".namespaces_for" do
    it "returns all namespaces for a source" do
      described_class.register("https://rubygems.org", :org1, "gem1")
      described_class.register("https://rubygems.org", :org2, "gem2")
      described_class.register("https://rubygems.org", :org3, "gem3")

      namespaces = described_class.namespaces_for("https://rubygems.org")
      expect(namespaces).to contain_exactly("org1", "org2", "org3")
    end

    it "returns empty array for source with no namespaces" do
      expect(described_class.namespaces_for("https://rubygems.org")).to eq([])
    end
  end

  describe ".registered?" do
    before do
      described_class.register("https://rubygems.org", :myorg, "my-gem")
    end

    it "returns true for registered gem" do
      expect(described_class.registered?("https://rubygems.org", :myorg, "my-gem")).to be true
    end

    it "returns false for unregistered gem" do
      expect(described_class.registered?("https://rubygems.org", :myorg, "other-gem")).to be false
    end

    it "returns false for wrong namespace" do
      expect(described_class.registered?("https://rubygems.org", :other, "my-gem")).to be false
    end
  end

  describe ".namespace_for" do
    it "returns namespace for uniquely registered gem" do
      described_class.register("https://rubygems.org", :myorg, "my-gem")

      expect(described_class.namespace_for("https://rubygems.org", "my-gem")).to eq("myorg")
    end

    it "returns nil for unregistered gem" do
      expect(described_class.namespace_for("https://rubygems.org", "unknown-gem")).to be_nil
    end

    it "raises error for gem registered in multiple namespaces" do
      described_class.register("https://rubygems.org", :org1, "my-gem")
      described_class.register("https://rubygems.org", :org2, "my-gem")

      expect {
        described_class.namespace_for("https://rubygems.org", "my-gem")
      }.to raise_error(Bundle::Namespace::NamespaceConflictError, /multiple namespaces/)
    end
  end

  describe ".all" do
    it "returns complete registry structure" do
      described_class.register("https://rubygems.org", :org1, "gem1")
      described_class.register("https://rubygems.org", :org2, "gem2")
      described_class.register("https://example.com", :org3, "gem3")

      all = described_class.all
      expect(all.keys).to contain_exactly("https://rubygems.org", "https://example.com")
      expect(all["https://rubygems.org"].keys).to contain_exactly("org1", "org2")
      expect(all["https://example.com"].keys).to contain_exactly("org3")
    end
  end

  describe ".size" do
    it "returns total count of registered gems" do
      expect(described_class.size).to eq(0)

      described_class.register("https://rubygems.org", :org1, "gem1")
      expect(described_class.size).to eq(1)

      described_class.register("https://rubygems.org", :org1, "gem2")
      described_class.register("https://rubygems.org", :org2, "gem3")
      expect(described_class.size).to eq(3)
    end
  end

  describe ".clear!" do
    it "clears all registrations" do
      described_class.register("https://rubygems.org", :myorg, "gem1")
      described_class.register("https://rubygems.org", :myorg, "gem2")

      expect(described_class.size).to eq(2)

      described_class.clear!

      expect(described_class.size).to eq(0)
      expect(described_class.all).to be_empty
    end
  end
end

