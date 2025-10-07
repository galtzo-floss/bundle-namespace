# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in bundle-namespace.gemspec
gemspec
source "https://gem.coop"
git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }
git_source(:gitlab) { |repo_name| "https://gitlab.com/#{repo_name}" }
eval_gemfile "gemfiles/modular/debug.gemfile"
eval_gemfile "gemfiles/modular/coverage.gemfile"
eval_gemfile "gemfiles/modular/style.gemfile"
eval_gemfile "gemfiles/modular/documentation.gemfile"
eval_gemfile "gemfiles/modular/optional.gemfile"
eval_gemfile "gemfiles/modular/x_std_libs.gemfile"
