require_relative "base_attribute"

class Bluepine::Attributes::ObjectAttributeTest < BaseAttribute
  let(:attribute_type) { :object }

  test_attribute_type { "object" }
  test_native_type { "object" }
  test_default_format { nil }

  test_custom_format do
    ["custom-format", create(format: "custom-format")]
  end

  test_validators do
    [
      { },
      create
    ]
  end

  describe "#method_missing" do
    it "should raise error" do
      assert_raises NameError do
        schema = create do
          non_exists
        end
      end
    end
  end

  describe "#group" do
    context "when options is given" do
      it "should assign default options to all attributes" do
        attr = create do
          group if: :deleted? do
            string :name1
            string :name2
          end

          group unless: :created? do
            string :address1
            string :address2
          end
        end

        2.times do |i|
          assert_equal :deleted?, attr["name#{i + 1}"].if
          assert_equal :created?, attr["address#{i + 1}"].unless
        end
      end

      context "nested group" do
        it "should allow nested conditions" do
          attr = create do
            string :name

            # 1st level
            group if: :deleted_1 do
              string :name_1
              object :nested do
                # 2nd level
                group if: :deleted_2 do
                  string :name_2
                end
              end
            end

            string :kitten
          end

          assert_equal :deleted_1, attr[:name_1].if
          assert_equal :deleted_2, attr[:nested][:name_2].if
          assert_nil attr[:kitten].if
        end
      end
    end
  end
end
