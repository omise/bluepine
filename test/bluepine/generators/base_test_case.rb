require "test_helper"
require_relative "../endpoints/fixtures"

class Bluepine::Generators::BaseTest < Minitest::Spec
  def create_method(path, verb: :post, params: nil, **options)
    params ||= lambda {
      string :email
    }

    method = Bluepine::Endpoints::Method.new(verb, action: :create, path: path, params: params, **options)
    method.build_params

    method
  end

  def create_object(name, &block)
    Bluepine::Attributes::ObjectAttribute.new(name, &block)
  end

  def create_attribute(type, *args)
    Bluepine::Attributes.create(type, *args)
  end
end
