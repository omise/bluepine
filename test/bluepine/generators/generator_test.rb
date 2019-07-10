require_relative "base_test_case"

class Bluepine::Generators::GeneratorTest < Bluepine::Generators::BaseTest
  let(:generator) { Bluepine::Generators::Generator.new }

  describe "#generate" do
    it "should raise NotImplementedError" do
      assert_raises NotImplementedError do
        generator.generate
      end
    end
  end
end
