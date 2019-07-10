require "test_helper"

class Bluepine::AssertionsTest < Minitest::Spec
  describe ".assert" do
    context "when passing a truthy value" do
      it "should not raise error" do
        Bluepine::Assertions.assert(true)
      end
    end

    context "when passing a falsey value" do
      it "should raise error" do
        assert_raises Bluepine::Assertions::Error do
          Bluepine::Assertions.assert(false)
        end
      end
    end
  end

  describe ".assert_not" do
    context "when passing a falsey value" do
      it "should not raise error" do
        Bluepine::Assertions.assert_not(false)
      end
    end

    context "when passing a truthy value" do
      it "should raise error" do
        assert_raises Bluepine::Assertions::Error do
          Bluepine::Assertions.assert_not(true)
        end
      end
    end
  end

  describe ".assert_kind_of" do
    context "when pass single argument as expected class" do
      it "should not raise error" do
        Bluepine::Assertions.assert_kind_of(String, "hello")
      end

      it "should raise error" do
        assert_raises Bluepine::Assertions::Error do
          Bluepine::Assertions.assert_kind_of(Symbol, "hello")
        end
      end
    end

    context "when passing multiple arguments as expected classes" do
      it "should not raise error" do
        Bluepine::Assertions.assert_kind_of([Symbol, String], "hello")
      end

      it "should raise error" do
        assert_raises Bluepine::Assertions::Error do
          Bluepine::Assertions.assert_kind_of([Symbol, Hash], "hello")
        end
      end
    end
  end

  describe ".assert_in" do
    context "when passing Array as expected value" do
      it "should not raise error" do
        Bluepine::Assertions.assert_in(%w[hello john], "hello")
      end

      it "should raise error" do
        assert_raises Bluepine::Assertions::KeyError do
          Bluepine::Assertions.assert_in([1, 2], "hello")
        end
      end
    end

    context "when passing Hash as expected value" do
      it "should not raise error" do
        Bluepine::Assertions.assert_in({ a: 1, b: 2 }, :a)
      end

      it "should raise error" do
        assert_raises Bluepine::Assertions::KeyError do
          Bluepine::Assertions.assert_in({ a: 1, b: 2 }, :c)
        end
      end
    end
  end

  describe ".assert_subset_of" do
    context "when subset is valid" do
      it "should not raise error" do
        Bluepine::Assertions.assert_subset_of(%i[a b], %i[a])
      end
    end

    context "when subset is not valid" do
      it "should raise error" do
        assert_raises Bluepine::Assertions::SubsetError do
          Bluepine::Assertions.assert_subset_of(%i[a b], %i[c])
        end
      end
    end
  end

  describe "error" do
    describe "Custom Error class" do
      before do
        @error_class = Class.new(StandardError) do
          def self.message
            "Custom class error message"
          end
        end

        @error_object = Class.new(StandardError) do
          def message
            "Custom class error message"
          end
        end
      end

      context "when passing custom Error class" do
        it "should raise that custom Error class instead" do
          assert_raises @error_class do
            Bluepine::Assertions.assert false, @error_class
          end
        end
      end

      context "when custom Error class has #message defined" do
        it "should use Error#message instead" do
          err = assert_raises @error_object do
            Bluepine::Assertions.assert false, @error_object
          end

          assert_match "Custom class error message", err.message
        end
      end

      context "when custom Error class has .message defined" do
        it "should use Error.message instead" do
          err = assert_raises @error_class do
            Bluepine::Assertions.assert false, @error_class
          end

          assert_match "Custom class error message", err.message
        end
      end
    end
  end
end
