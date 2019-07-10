require "test_helper"

class BaseAttribute < Minitest::Spec
  def create(options = {}, &block)
    name = options[:name] || attribute_type
    Bluepine::Attributes.registry.create(attribute_type, name, options, &block || -> {})
  end

  class << self
    def test(task, method, context, title: nil, &block)
      describe title || "#{name.demodulize}##{method}" do
        it task do
          expected, attribute = instance_exec(&context)
          if attribute.nil?
            attribute = instance_exec(&block)
          end

          actual = attribute.send(method)

          if expected.nil?
            assert_nil actual
          else
            assert_equal expected, actual
          end
        end
      end
    end

    def test_attribute_type(&block)
      test("should return attribute type", :type, block) { create }
    end

    def test_native_type(&block)
      test("should return native type value", :native_type, block) { create }
    end

    def test_default_format(&block)
      test("should return default format", :format, block) { create }
    end

    def test_custom_format(&block)
      test("should return custom format", :format, block)
    end

    def test_validators(&block)
      test("should convert validation rules", :validators, block)
    end
  end
end
