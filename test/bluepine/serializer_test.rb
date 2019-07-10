require "test_helper"

class Bluepine::SerializerTest < Minitest::Spec
  before do
    @schemas = []
  end

  def create_schema(name, &block)
    @schemas.push(create_attribute(:object, name, &block))
    @schemas.last
  end

  def serializer
    resolver    = create_resolver(schemas: @schemas)
    @serializer ||= Bluepine::Serializer.new(resolver)
  end

  def serialize(*args)
    serializer.serialize(*args)
  end

  def expect_result(attribute, value, expected)
    result = serialize(attribute, value)
    assert_equal expected, result
  end

  def create_users_stub(attributes = {}, size = 3)
    create_users({
      enabled: "true",
    }, size)
    .map { |user| stub(user) }
  end

  let(:user_schema) {
    create_schema(:user) do
      string  :username
      string  :password
      boolean :enabled
    end
  }

  TEST_CASES = {
    string: [
      ["string", "string"],
      [:string,  "string"],
      [1, "1"],
      [true, "true"],
    ],
    boolean: [
      [true, true],
      ["yes", true],
      [1, true],
      [0, false],
    ],
    number: [
      [1, 1],
      ["1", 1],
      ["1.3", 1.3],
      ["1.2", 1.2],
      [1.2, 1.2],
    ],
    integer: [
      ["1", 1],
      ["1.2", 1],
    ],
    float: [
      [1, 1.0],
      ["1", 1.0],
      ["1.2", 1.2],
    ]
  }

  describe "#serialize" do
    TEST_CASES.each do |attribute, cases|
      describe "#visit_#{attribute}" do
        it "should serialize #{attribute} attribute" do
          attr = create_attribute(attribute, :name)

          # run each test case
          cases.each do |test|
            value, expected = test
            actual = serialize(attr, value)

            assert_equal expected, actual
          end
        end
      end
    end

    describe "Custom serializer" do
      BooleanAttribute = Bluepine::Attributes::BooleanAttribute

      let(:user_schema) { create_user_schema }

      before do
        @default = BooleanAttribute.serializer

        # Override default serializer converting 'on' and 'yes' to true
        BooleanAttribute.serializer = ->(x) { %w[on yes].include?(x) ? true : false }
      end

      after do
        BooleanAttribute.serializer = @default
      end

      it "should serialize value with custom serializer" do
        user = {
          other: "on",
          name: 123,
          team: {
            enabled: "no!"
          }
        }

        expected = {
          other: true,
          name: "123",
          team: {
            enabled: false
          }
        }

        expect_result user_schema, user, expected
      end
    end

    describe "options" do
      context "when custom :method name is given" do
        it "should use custom method name for value" do
          schema = create_schema(:user) do
            string  :username, method: :custom_name
          end

          user = stub({
            custom_name: "john",
          })

          expect_result schema, user, {
            username: "john",
          }
        end
      end

      describe ":private option" do
        context "when private: true" do
          it "should not serialize this attribute" do
            user_schema = create_schema(:user) do
              string :username
              string :password, private: true
            end

            user_stub = create_users_stub.first

            expect_result user_schema, user_stub, username: "user_1"
          end
        end
      end

      describe ":if/:unless option" do
        before do
          @user_schema = create_schema(:user) do
            string  :name_symbol_true,  if: :deleted
            string  :name_symbol_false, unless: :deleted
            string  :name_proc_true,    if: ->(o) { o.deleted }
            string  :name_proc_false,   unless: ->(o) { o.deleted }
            boolean :deleted
          end

          @result = {
            name_symbol_true: "symbol 1",
            name_symbol_false: "symbol 2",
            name_proc_true: "proc 1",
            name_proc_false: "proc 2",
          }
        end

        context "when :if/unless is not valid value" do
          it "should raise error" do
            assert_raises Bluepine::Serializer::InvalidPredicate do
              schema = create_schema(:user) do
                string :name, if: "some invalid"
              end

              serialize(schema, [])
            end
          end
        end

        context "when result is evaluated to true" do
          it "should include attribute in the result" do
            result   = serialize(@user_schema, stub(@result.merge(deleted: true)))
            expected = {
              name_symbol_true: "symbol 1",
              name_proc_true: "proc 1",
              deleted: true,
            }

            assert_equal expected, result
          end
        end

        context "when result is evaluated to false" do
          it "should exclude attribute from the result" do
            result   = serialize(@user_schema, stub(@result.merge(deleted: false)))
            expected = {
              name_symbol_false: "symbol 2",
              name_proc_false: "proc 2",
              deleted: false,
            }

            assert_equal expected, result
          end
        end

        describe "#group with :if/:else" do
          before do
            @schema = create_schema(:user) do
              string  :name1
              group if: :deleted do
                string  :name2
                string  :name3
              end

              boolean :deleted
            end

            @result = {
              name1: "1",
              name2: "2",
              name3: "3",
            }
          end

          context "when result is evaluated to true" do
            it "should include attribute in the result" do
              result   = serialize(@schema, @result.merge(deleted: true))
              expected = {
                name1: "1",
                name2: "2",
                name3: "3",
                deleted: true,
              }

              assert_equal expected, result
            end
          end

          context "when result is evaluated to false" do
            it "should exclude attribute in the result" do
              result   = serialize(@schema, @result.merge(deleted: false))
              expected = {
                name1: "1",
                deleted: false,
              }

              assert_equal expected, result
            end
          end
        end
      end
    end

    describe "#visit_attribute" do
      AwesomeAttribute = Class.new(Bluepine::Attributes::Attribute)

      before do
        @attribute = AwesomeAttribute.new(:name)
      end

      context "when there's no implementation for #visit_{attribute} method" do
        it "should fallback to #visit_attribute" do
          data   = (1..3).to_a

          actual = serialize(@attribute, data)
          assert_equal data, actual
        end

        it "should ensure that #visit_attribute get called" do
          serializer.expects(:visit_attribute).once
          serialize(@attribute, [])
        end
      end
    end

    describe "#visit_array" do
      it "should serialize array" do
        attr   = create_attribute(:array, :name)
        data   = (1..20)
        actual = serialize(attr, data)

        assert_equal data.to_a, actual
      end

      context "when :of is given" do
        context "when :of refers to attribute" do
          it "should serialize each value based on given attribute type" do
            attr     = create_attribute(:array, :name, of: :integer)
            data     = [1, "2", "3", "4.5", 5.5, 6.0]
            actual   = serialize(attr, data)
            expected = (1..6).to_a

            assert_equal expected, actual
          end
        end

        context "when :of refers to schema" do
          before do
            user_schema
          end

          it "should serialize value based on given :schema" do
            attr     = create_attribute(:array, :name, of: :user)
            data     = create_users_stub
            expected = create_users(enabled: true)

            expect_result attr, data, expected
          end
        end
      end
    end

    describe "#visit_object" do
      it "should serialize object attribute" do
        data     = create_users_stub.first
        expected = create_users(enabled: true).first

        expect_result user_schema, data, expected
      end

      context "nested object" do
        it "should serialize nested object attribute" do
          schema = create_schema(:user) do
            string  :username
            object :father do
              string  :firstname
              boolean :enabled
              object :father do
                string  :lastname
                boolean :enabled
              end
            end
          end

          user = stub({
            username: "john",
            father: stub({
              firstname: "joe",
              enabled: "true",
              father: stub({
                lastname: "snow",
                enabled: "false",
              })
            })
          })

          expect_result schema, user, {
            username: "john",
            father: {
              firstname: "joe",
              enabled: true,
              father: {
                lastname: "snow",
                enabled: false,
              }
            }
          }
        end
      end
    end

    describe "visit_schema" do
      before do
        user_schema
      end

      it "should serialize object based on given schema" do
        attribute = create_attribute(:schema, :name, of: :user)
        data      = create_users_stub.first
        expected  = create_users(enabled: true).first

        expect_result attribute, data, expected
      end

      context "when no :of option given" do
        it "should use attribute name as schema name" do
          team_schema = create_schema(:team) do
            string :name
            schema :user # same as `schema :user, of: :user`
          end

          data = stub({
            name: 111,
            user: create_users_stub.first
          })

          expected = {
            name: "111",
            user: create_users(enabled: true).first
          }

          expect_result team_schema, data, expected
        end
      end

      context "nested schema" do
        it "should serialize nested schema" do
          # company.team.user
          create_schema(:team) do
            string :name
            schema :owner, of: :user
            array  :members, of: :user
          end

          company_schema = create_schema(:company) do
            string :name
            schema :team, of: :team
          end

          company_data = stub({
            name: 111,
            team: stub({
              name: 222,
              owner: create_users_stub.first,
              members: create_users_stub,
            })
          })

          expected = {
            name: "111",
            team: {
              name: "222",
              owner: create_users(enabled: true).first,
              members: create_users(enabled: true),
            }
          }

          expect_result company_schema, company_data, expected
        end
      end
    end
  end
end
