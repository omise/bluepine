require "test_helper"

class Bluepine::Validators::ProxyTest < Minitest::Spec
  alias :create :create_proxy

  let(:proxy) { create(create_attribute(:string, :username), "john") }

  describe "#new" do
    it "should normalize given value" do
      assert_equal "john", proxy.value
    end

    it "should return default value when :default option is given" do
      proxy = create(create_attribute(:string, :username, default: "joe"))

      assert_equal "joe", proxy.value
    end
  end

  describe "#method_missing" do
    it "should return given value" do
      value = "some data"
      proxy = create(create_attribute(:string, :username), value)

      assert_equal value, proxy.username
    end

    context "when Attribute#name is string" do
      it "should have no different when referring to it with Symbol" do
        value = "john"
        proxy = create(create_attribute(:string, "username"), value)

        assert_equal value, proxy.username
      end
    end

    context "when :context option is given" do
      it "should return value in :context when it can't find from default key" do
        value = "password"
        proxy = create(create_attribute(:string, "username"), nil, context: { password: value })

        assert_equal value, proxy.password
      end
    end
  end

  describe "#respond_to?" do
    it "should respond to method call" do
      assert proxy.respond_to?(:username)
    end
  end

  describe "#valid?" do
    it "should return true when value is valid" do
      assert proxy.valid?
    end

    it "should return false when value is invalid" do
      proxy = create(create_attribute(:string, :username, required: true), nil)

      refute proxy.valid?
      assert_equal ["can't be blank"], proxy.errors.messages[:username]
    end

    it "should support rails's validation rules" do
      proxy = create(create_attribute(:string, :username, min: 5), "john")

      refute proxy.valid?
      assert_equal ["is too short (minimum is 5 characters)"], proxy.errors.messages[:username]
    end
  end
end
