require "lygens/model/parser"
require "lygens/model/model"

RSpec.describe Lyg::ObjectParser do
    before(:each) do
        # Supress warnings about overwritten constant
        original_verbose = $VERBOSE
        $VERBOSE = nil
        Person = Lyg::Model.define do
            field :name do
            end

            field :age do
            end

            field :email do
            end
        end
        $VERBOSE = original_verbose

        @obj1 = {
            "name" => "Test",
            "age" => 20,
            "email" => "test@test.se"
        }

        @obj2 = {
            "name" => "Test2",
            "age" => 22,
            "email" => "test2@test.se"
        }

        @arr = [@obj1, @obj2]

        @parser = Lyg::ObjectParser.new
    end

    describe "#parse_as" do
        context "when given hash" do
            it "should parse that hash as a single object" do
                person = @parser.parse_as(Person, @obj1)
                expect(person.name).to eq("Test")
                expect(person.age).to eq(20)
                expect(person.email).to eq("test@test.se")
            end
        end

        context "when given array" do
            it "should parse that array as a list of objects" do
                persons = @parser.parse_as(Person, @arr)

                person1 = persons[0]
                expect(person1.name).to eq("Test")
                expect(person1.age).to eq(20)
                expect(person1.email).to eq("test@test.se")

                person2 = persons[1]
                expect(person2.name).to eq("Test2")
                expect(person2.age).to eq(22)
                expect(person2.email).to eq("test2@test.se")
            end
        end

        context "when given object that is neither hash or array" do
            it "should raise TypeError" do
                expect do
                    @parser.parse_as(Person, "hei")
                end.to raise_error(TypeError)
            end
        end
    end
end

RSpec.describe Lyg::ObjectParser do
    before(:each) do
        # Supress warnings about overwritten constant
        original_verbose = $VERBOSE
        $VERBOSE = nil
        Person = Lyg::Model.define do
            field :name do
            end

            field :age do
            end

            field :email do
            end
        end
        $VERBOSE = original_verbose

        @obj = <<-OBJ
        {
            "name": "Test",
            "age": 20,
            "email": "test@test.se"
        }
        OBJ
        @arr = <<-ARR
        [
            {
                "name": "Test",
                "age": 20,
                "email": "test@test.se"
            },
            {
                "name": "Test2",
                "age": 22,
                "email": "test2@test.se"
            }
        ]
        ARR

        @parser = Lyg::JsonParser.new
    end

    describe "#parse_as" do
        context "when called with a string containing an object" do
            it "should parse that string as a single object" do
                person = @parser.parse_as(Person, @obj)
                expect(person.name).to eq("Test")
                expect(person.age).to eq(20)
                expect(person.email).to eq("test@test.se")
            end
        end

        context "when called with a string containing an array" do
            it "should parse that string as an array of objects" do
                persons = @parser.parse_as(Person, @arr)

                person1 = persons[0]
                expect(person1.name).to eq("Test")
                expect(person1.age).to eq(20)
                expect(person1.email).to eq("test@test.se")

                person2 = persons[1]
                expect(person2.name).to eq("Test2")
                expect(person2.age).to eq(22)
                expect(person2.email).to eq("test2@test.se")
            end
        end

        context "when called with an invalid json string" do
            it "should raise ParserError" do
                expect do
                    @parser.parse_as(Person, "{\"name; 10\"}")
                end.to raise_error(Lyg::ParserError)
            end
        end

        context "when called with an object that is not a string" do
            it "should raise TypeError" do
                expect do
                    @parser.parse_as(Person, 20)
                end.to raise_error(TypeError)
            end
        end
    end
end
