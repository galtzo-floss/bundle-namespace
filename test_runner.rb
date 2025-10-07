#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple test runner to verify basic functionality without full test suite
require "bundle/namespace/registry"
require "bundle/namespace/configuration"
require "bundle/namespace/errors"

puts "Testing Bundle::Namespace Core Components"
puts "=" * 60

# Test Registry
puts "\n[Registry Tests]"
Bundle::Namespace::Registry.clear!
Bundle::Namespace::Registry.register("https://rubygems.org", :myorg, "gem1")
Bundle::Namespace::Registry.register("https://rubygems.org", :myorg, "gem2")

gems = Bundle::Namespace::Registry.gems_for("https://rubygems.org", :myorg)
if gems.sort == ["gem1", "gem2"]
  puts "✓ Registry.register and gems_for work correctly"
else
  puts "✗ Registry test failed: expected [gem1, gem2], got #{gems.inspect}"
  exit 1
end

namespace = Bundle::Namespace::Registry.namespace_for("https://rubygems.org", "gem1")
if namespace == "myorg"
  puts "✓ Registry.namespace_for works correctly"
else
  puts "✗ namespace_for test failed: expected 'myorg', got #{namespace.inspect}"
  exit 1
end

# Test Configuration
puts "\n[Configuration Tests]"
Bundle::Namespace::Configuration.reset!
if Bundle::Namespace::Configuration.strict_mode? == false
  puts "✓ Configuration.strict_mode defaults to false"
else
  puts "✗ strict_mode default test failed"
  exit 1
end

Bundle::Namespace::Configuration.strict_mode = true
if Bundle::Namespace::Configuration.strict_mode? == true
  puts "✓ Configuration.strict_mode can be set to true"
else
  puts "✗ strict_mode setter test failed"
  exit 1
end

if Bundle::Namespace::Configuration.lockfile_path == "bundler-namespace-lock.yaml"
  puts "✓ Configuration.lockfile_path has correct default"
else
  puts "✗ lockfile_path default test failed"
  exit 1
end

# Test Errors
puts "\n[Error Tests]"
begin
  raise Bundle::Namespace::NamespaceConflictError.new("my-gem", "org1", "org2")
rescue Bundle::Namespace::NamespaceConflictError => e
  if e.message.include?("my-gem") && e.message.include?("org1") && e.message.include?("org2")
    puts "✓ NamespaceConflictError has correct message"
  else
    puts "✗ NamespaceConflictError message test failed"
    exit(1)
  end
end

begin
  raise Bundle::Namespace::NamespaceNotSupportedError.new("https://example.com")
rescue Bundle::Namespace::NamespaceNotSupportedError => e
  if e.message.include?("https://example.com") && e.message.include?("does not support")
    puts "✓ NamespaceNotSupportedError has correct message"
  else
    puts "✗ NamespaceNotSupportedError message test failed"
    exit(1)
  end
end

puts "\n" + "=" * 60
puts "All core component tests passed! ✓"
puts "=" * 60
