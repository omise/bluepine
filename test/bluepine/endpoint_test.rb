require "test_helper"

class Bluepine::Endpoints::EndpointTest < Minitest::Spec
  before do
    @endpoint = create_endpoint("/charges", schema: :charge)
  end

  let(:resolver) {
    create_resolver(
      endpoints: [
        create_endpoint("/list") do
          get :all, path: "/"
        end
      ]
    )
  }

  describe "#new" do
    it "should have common http methods defined" do
      Bluepine::Endpoint::HTTP_METHODS.each do |method|
        assert @endpoint.respond_to? method
      end
    end
  end

  describe "#define_method" do
    methods = [
      { verb: :get, path: "/", action: :index },
      { verb: :post, path: "/", action: :create },
      { verb: :patch, path: "/:id", action: :update },
      { verb: :put, path: "/:id", action: :update },
      { verb: :delete, path: "/", action: :destroy },
    ]

    methods.each do |method|
      it "should create new method for #{method[:verb]}" do
        @endpoint.send(method[:verb], method[:action], path: method[:path])

        result = @endpoint.method(method[:action])
        assert_instance_of Bluepine::Endpoints::Method, result
        assert_equal method[:verb], result.verb
        assert_equal method[:path], result.path
        assert_equal method[:action], result.action
        assert_equal create_params(method[:action]).keys, result.params.keys
      end
    end

    context "when creating method with default options" do
      it "should use default values" do
        method = @endpoint.post :create

        assert_equal "/", method.path
        assert_equal :post, method.verb
        assert_equal :create, method.action
        assert_instance_of Bluepine::Endpoints::Params, method.params
      end

      it "should automatically add :schema value to #method" do
        method = @endpoint.post :create
        assert_equal :charge, method.schema
      end
    end

    context "when :schema is given" do
      it "should override default :schema" do
        method = @endpoint.post :create, schema: :thing

        assert_equal :thing, method.schema
      end
    end

    describe "params: option" do
      before do
        @endpoint = create_endpoint("/charges") do
          # default params
          params do
            integer :amount
            string :currency
          end
        end
      end

      context "when params: is not given (i.e. params: false)" do
        it "should not use params" do
          @endpoint.post :create
          expected = create_params(:create)

          assert_equal expected.options, @endpoint.method(:create).params.options
          assert_equal [], @endpoint.method(:create).params.keys
        end
      end

      context "when params: is given" do
        it "should not build params until needed (lazy)" do
          method = @endpoint.post :create, params: %i[amount]
          assert_equal %i[amount], method.params.params

          # calling #methods will build all params
          assert_instance_of Bluepine::Endpoints::Params, @endpoint.method(:create).params
        end

        it "should override default params" do
          @endpoint.post :create, params: %i[amount]
          expected = create_params(:create) do
            integer :amount
          end

          assert_equal expected.options, @endpoint.method(:create).params.options
          assert_equal %i[amount], @endpoint.method(:create).params.keys
        end

        it "should raise error when trying to specify invalid param" do
          assert_raises Bluepine::Assertions::SubsetError do
            @endpoint.post :create, params: %i[invalid_key bad_key]
            @endpoint.methods
          end
        end
      end

      context "when params: is Proc" do
        it "should override default params" do
          @endpoint.post :create, params: lambda {
            string :username
            string :password
          }
          expected = create_params(:create) do
            string :username
            string :password
          end

          assert_equal expected.options, @endpoint.method(:create).params.options
          assert_equal %i[username password], @endpoint.method(:create).params.keys
        end
      end

      context "when params: true" do
        it "should return default params" do
          @endpoint.post :create, params: true

          assert_equal @endpoint.params.options, @endpoint.method(:create).params.options
          assert_equal %i[amount currency], @endpoint.method(:create).params.keys
        end
      end

      context "when params: is Symbol" do
        it "should find params from other endpoint" do
          @endpoint.post :create, params: :list
          expected = resolver.endpoint(:list).params

          assert_equal expected, @endpoint.method(:create, resolver: resolver).params
        end
      end

      context "when exclude: true" do
        it "should exclude specified params" do
          @endpoint.post :create, params: %i[amount], exclude: true
          expected = create_params(:create, exclude: true) do
            string :currency
          end

          assert_equal expected.options, @endpoint.method(:create).params.options
          assert_equal %i[currency], @endpoint.method(:create).params.keys
        end
      end
    end
  end

  describe "#params" do
    context "when creating with default options" do
      it "should have @params defined" do
        @endpoint.params do
          integer :amount
          string :currency
        end
        amount_attr   = @endpoint.params[:amount].options
        currency_attr = @endpoint.params[:currency].options

        # amount attribute
        assert_instance_of Bluepine::Endpoints::Params, @endpoint.params
        refute amount_attr[:required]
        assert_equal :amount, amount_attr[:name]

        # currency attribute
        refute currency_attr[:required]
        assert_equal :currency, currency_attr[:name]
      end
    end
  end

  describe "#validators" do
    class CustomPasswordValidator < ActiveModel::Validator
      def validate(record)
        record.errors.add(:password, "is too short") unless record.password.length > 10
      end
    end

    it "should support custom validators" do
      @endpoint.post :create, params: lambda {
        string :username, required: true
        string :password, required: true, validators: [CustomPasswordValidator]
      }

      data = {
        username: "john",
        password: "doe",
      }

      method = @endpoint.method(:create)
      errors = {
        password: ["is too short"],
      }

      method.valid?(data)
      assert_equal errors, method.errors
    end
  end

  describe "#valid?" do
    before do
      @endpoint.post :create, params: lambda {
        string :username, required: true
        string :password, required: true
        object :custom do
          string :name, required: true
        end
      }
    end

    context "when given data is valid" do
      it "should pass the test" do
        data = {
          username: "John",
          password: "Doe",
          custom: {
            name: "custom name",
          },
        }

        method = @endpoint.method(:create)
        errors = {}

        assert_nil method.valid?(data)
      end
    end

    context "when given data is invalid" do
      it "should pass the test" do
        data = {
          username: "John",
          password: nil,
          custom: {},
        }

        method = @endpoint.method(:create)
        errors = {
          password: ["can't be blank"],
          custom: {
            name: ["can't be blank"],
          },
        }

        refute method.valid?(data)
        assert_equal errors, method.errors
      end
    end
  end
end
