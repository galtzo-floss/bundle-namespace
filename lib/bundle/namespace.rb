# frozen_string_literal: true

require_relative "namespace/version"
require_relative "namespace/errors"
require_relative "namespace/registry"
require_relative "namespace/configuration"
require_relative "namespace/dsl_extension"
require_relative "namespace/dependency_extension"
require_relative "namespace/source_extensions"
require_relative "namespace/resolver_extension"
require_relative "namespace/specification_extension"
require_relative "namespace/lockfile_generator"
require_relative "namespace/lockfile_parser"
require_relative "namespace/lockfile_validator"
require_relative "namespace/plugin"

module Bundle
  module Namespace
    class Error < StandardError; end
  end
end
