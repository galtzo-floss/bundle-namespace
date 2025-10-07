# frozen_string_literal: true

RSpec.describe Bundle::Namespace do
  it "has a version number" do
    expect(Bundle::Namespace::VERSION).not_to be_nil
  end

  it "loads all core components" do
    expect(defined?(Bundle::Namespace::Registry)).to eq("constant")
    expect(defined?(Bundle::Namespace::Configuration)).to eq("constant")
    expect(defined?(Bundle::Namespace::Plugin)).to eq("constant")
    expect(defined?(Bundle::Namespace::DslExtension)).to eq("constant")
    expect(defined?(Bundle::Namespace::DependencyExtension)).to eq("constant")
  end

  it "defines all error classes" do
    expect(defined?(Bundle::Namespace::Error)).to eq("constant")
    expect(defined?(Bundle::Namespace::NamespaceConflictError)).to eq("constant")
    expect(defined?(Bundle::Namespace::NamespaceNotSupportedError)).to eq("constant")
  end
end
