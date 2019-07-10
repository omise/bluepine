$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'simplecov'
SimpleCov.start

require "bluepine"

require "pp"
require "action_controller"
require "minitest/autorun"
require "minitest/spec"
require "mocha/minitest"
require_relative "helper"

class Minitest::Test
  include Helper

  class << self
    alias_method :context, :describe
  end
end
