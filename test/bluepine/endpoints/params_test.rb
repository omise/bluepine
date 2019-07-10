require "test_helper"

class Bluepine::Endpoints::ParamsTest < Minitest::Spec
  def create_params(action: :create, **options)
    Bluepine::Endpoints::Params.new(action, options)
  end

  def create_action_params(params = {})
    ActionController::Parameters.new(params)
  end

  describe "#build" do
    context "when params is instance of Params" do
      it "should return the same params object" do
        params = create_params(params: false)
        actual = create_params(params: params).build

        assert_equal params, actual
      end
    end

    context "when invalid params type given" do
      it "should raise InvalidParamsType error" do
        assert_raises Bluepine::Endpoints::Params::InvalidType do
          create_params(params: "Test").build
        end
      end
    end
  end

  describe "#permit" do
    context "when params has not been built" do
      it "should raise error" do
        assert_raises Bluepine::Endpoints::Params::NotBuilt do
          create_params(params: nil).permit
        end
      end
    end

    context "when params has been built" do
      before do
        @params = create_params(built: true, params: lambda {
          string :username
          array  :pets
          object :profile do
            string :name
            array  :pets
            object :extra do
              string :info
            end
          end

          # arbitrary hash
          object :meta
        })
        @params.build
      end

      it "should build an array of permitted params" do
        expected = [
          :username,
          { :pets => [] },
          {
            profile: [
              :name,
              { :pets => [] },
              {
                extra: %i[info],
              },
            ],
          },
          {
            meta: {},
          },
        ]

        assert_equal expected, @params.permit
      end

      context "when using it with ActionController::Parameters" do
        it "shoud only allow permitted params" do
          action_params = create_action_params({
            username: "John",
            username2: "john@doe.com",
            profile: {
              name: "Johny",
              extra: {
                info: "Info",
                info2: "Info 2",
              },
            },
          })
          expected = {
            "username" => "John",
            "profile" => {
              "name" => "Johny",
              "extra" => {
                "info" => "Info",
              },
            },
          }
          result = action_params.permit(*@params.permit)

          assert_equal expected, result.to_h
        end

        context "when validating arbitrary hash structure" do
          it "should allow any hash structure defined in params definition" do
            action_params = create_action_params({
              other: "Not allow",
              meta: {
                name: "Johny",
                info: "Info",
              },
            })
            expected = {
              "meta" => {
                "name" => "Johny",
                "info" => "Info",
              },
            }
            result = action_params.permit(*@params.permit(action_params))

            assert_equal expected, result.to_h
          end
        end
      end
    end
  end
end
