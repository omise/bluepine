require "test_helper"

class Bluepine::Attributes::VisitorTest < Minitest::Spec
  describe "Visitor" do
    NilAttribute = Class.new(Bluepine::Attributes::Attribute)

    let(:visitor) { Bluepine::Attributes::Visitor.new }

    describe "#visit_attribute" do
      it "should raise NotImplementedError" do
        assert_raises NotImplementedError do
          visitor.visit_attribute(nil)
        end
      end
    end

    describe "#visit" do
      context "when attribute is Symbol e.g. visit(:user)" do
        it "should call visit_schema with {of: :user}" do
          attr = create_attribute(:string, :test)
          visitor.stubs(:normalize_attribute).returns(attr)
          visitor.expects(:visit_schema).once.with(attr, {of: :user})

          visitor.visit(:user, {})
        end
      end
    end

    describe "#find_method" do
      context "when it can find visit_{attribute.name}" do
        it "should return visit_{attribute.name}" do
          visitor.stubs(:visit_string)
          attr     = create_attribute(:string, :test)
          result   = visitor.send(:find_method, attr)
          expected = ["visit_string", attr]

          assert_equal expected, result
        end
      end

      context "when it cannot find visit_{attribute.name} method" do
        it "should return visit_attribute" do
          attr     = NilAttribute.new(:test)
          result   = visitor.send(:find_method, attr)
          expected = ["visit_attribute", attr]

          assert_equal expected, result
        end
      end

      context "when CustomAttribute is not a sub-class of Attribute" do
        it "should return nil" do
          result = visitor.send(:find_method, Hash)

          assert_equal [nil, Hash], result
        end
      end

      context "when attribute is Symbol" do
        it "should return visit_{symbol} method" do
          visitor.stubs(:visit_custom_attribute)

          result   = visitor.send(:find_method, :custom_attribute)
          expected = ["visit_custom_attribute", :custom_attribute]

          assert_equal expected, result
        end
      end
    end
  end
end
