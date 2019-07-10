require "test_helper"

class Bluepine::Endpoints::MethodTest < Minitest::Spec
  alias :create :create_method

  def create_action_params(params)
    ActionController::Parameters.new(params)
  end

  describe "#permit_params" do
    before do
      @method = create(:post, action: :create, params: lambda {
        string :username
        string :password
        array  :friends
      })
      @method.build_params
    end

    context "when params doesn't respond to :permit method" do
      it "should return exact params back" do
        params = { username: "john" }
        actual = @method.permit_params(params)

        assert_equal params, actual
      end
    end

    context "when params respond to :permit method" do
      it "should set permit params" do
        params = {
          "username" => "john",
          "password" => "doe",
          "friends"  => [1, 2],
        }

        invalid_params = {
          other_field1: [1, 2],
          other_field2: [1, 2],
        }

        action_params = create_action_params(params.merge(invalid_params))
        actual        = @method.permit_params(action_params)

        assert_instance_of ActionController::Parameters, actual
        assert_equal params.to_h, actual.to_h
      end
    end
  end
end
