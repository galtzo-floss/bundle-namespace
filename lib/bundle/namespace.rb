# frozen_string_literal: true

require_relative "namespace/version"
require_relative "namespace/errors"
require_relative "namespace/registry"
require_relative "namespace/configuration"
require_relative "namespace/plugin"

module Bundle
  module Namespace
    class Error < StandardError; end
  end
end
