# frozen_string_literal: true

require "spec_helper"
require "bundler"
require "bundler/dsl"

RSpec.describe Bundle::Namespace::DslExtension do
  let(:dsl) { Bundler::Dsl.new }

  before do
    Bundle::Namespace::Registry.clear!
    # Ensure the extension is loaded
    Bundle::Namespace::Plugin.install!
  end

  after do
    Bundle::Namespace::Registry.clear!
  end

  describe "#namespace" do
    it "accepts a block with namespace identifier" do
      expect {
        dsl.instance_eval do
          namespace :myorg do
            # gem declarations would go here
          end
        end
      }.not_to raise_error
    end

    it "requires a block" do
      expect {
        dsl.instance_eval do
          namespace :myorg
        end
      }.to raise_error(ArgumentError, /requires a block/)
    end

    it "requires at least one namespace identifier" do
      expect {
        dsl.instance_eval do
          namespace do
            # empty
          end
        end
      }.to raise_error(ArgumentError, /requires at least one/)
    end

    it "supports multiple namespace identifiers" do
      expect {
        dsl.instance_eval do
          namespace :org1, :org2 do
            # gem declarations would go here
          end
        end
      }.not_to raise_error
    end

    it "properly cleans up namespace stack after block" do
      dsl.instance_eval do
        namespace :myorg do
          # inside namespace
        end
        # outside namespace - @namespaces should be empty
      end

      # Verify namespace was cleaned up
      namespaces = dsl.instance_variable_get(:@namespaces)
      expect(namespaces).to be_empty
    end

    it "supports nested namespaces" do
      expect {
        dsl.instance_eval do
          namespace :outer do
            namespace :inner do
              # gem declarations
            end
          end
        end
      }.not_to raise_error
    end
  end

  describe "#gem with namespace option" do
    it "accepts namespace as an option" do
      # Mock the source
      allow(dsl).to receive(:normalize_options)
      allow(dsl).to receive(:add_dependency)

      expect {
        dsl.gem "my-gem", namespace: :myorg
      }.not_to raise_error
    end

    it "accepts namespace as a string key" do
      allow(dsl).to receive(:normalize_options)
      allow(dsl).to receive(:add_dependency)

      expect {
        dsl.gem "my-gem", "namespace" => :myorg
      }.not_to raise_error
    end
  end

  describe "namespace tracking in dependencies" do
    it "tracks namespace in dependency when gem is declared in namespace block" do
      # Mock normalize_options to prevent errors
      allow(dsl).to receive(:normalize_options)

      # Declare gem in namespace
      dsl.instance_eval do
        namespace :myorg do
          gem "test-gem"
        end
      end

      # Verify the gem was registered with the namespace
      expect(Bundle::Namespace::Registry.registered?(nil, :myorg, "test-gem")).to be true

      # Verify we can retrieve the namespace for the gem
      namespace = Bundle::Namespace::Registry.namespace_for(nil, "test-gem")
      expect(namespace).to eq("myorg")
    end

    it "registers gems in the namespace registry" do
      # Mock just enough to test registration
      allow(dsl).to receive(:normalize_options)

      dsl.instance_eval do
        namespace :myorg do
          gem "test-gem"
        end
      end

      # The gem should be registered
      expect(Bundle::Namespace::Registry.registered?(nil, :myorg, "test-gem")).to be true
    end

    it "handles multiple gems in the same namespace" do
      allow(dsl).to receive(:normalize_options)

      dsl.instance_eval do
        namespace :myorg do
          gem "gem1"
          gem "gem2"
          gem "gem3"
        end
      end

      gems = Bundle::Namespace::Registry.gems_for(nil, :myorg)
      expect(gems).to contain_exactly("gem1", "gem2", "gem3")
    end

    it "handles gems in different namespaces" do
      allow(dsl).to receive(:normalize_options)

      dsl.instance_eval do
        namespace :org1 do
          gem "gem1"
        end

        namespace :org2 do
          gem "gem2"
        end
      end

      expect(Bundle::Namespace::Registry.gems_for(nil, :org1)).to eq(["gem1"])
      expect(Bundle::Namespace::Registry.gems_for(nil, :org2)).to eq(["gem2"])
    end
  end

  describe "namespace with option syntax" do
    it "registers gem with namespace option" do
      allow(dsl).to receive(:normalize_options)

      dsl.gem "test-gem", namespace: :myorg

      expect(Bundle::Namespace::Registry.registered?(nil, :myorg, "test-gem")).to be true
    end

    it "properly cleans up after option syntax" do
      allow(dsl).to receive(:normalize_options)

      dsl.gem "test-gem", namespace: :myorg

      # Namespace stack should be empty after gem declaration
      namespaces = dsl.instance_variable_get(:@namespaces)
      expect(namespaces).to be_empty
    end
  end
end
