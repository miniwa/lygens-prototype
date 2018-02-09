require "lygens/model/model"

RSpec.describe Lyg::Model do
    describe "#define" do
        it "should create a model with the proper fields" do
            Person1 = Lyg::Model.define do
                field :name do
                    required true
                end

                field :age do
                    key :years_old
                    default 0
                end
            end

            name_field = Person1.fields[0]
            expect(name_field.name).to eq(:name)
            expect(name_field.key).to eq(:name)
            expect(name_field.required).to eq(true)
            expect(name_field.default).to eq(nil)

            age_field = Person1.fields[1]
            expect(age_field.name).to eq(:age)
            expect(age_field.key).to eq(:years_old)
            expect(age_field.required).to eq(false)
            expect(age_field.default).to eq(0)
        end

        it "should return a model that has assignable fields representing the"\
        " definition" do
            Person2 = Lyg::Model.define do
                field :name do
                end
            end

            person = Person2.new
            person.name = "test"
            expect(person.name).to eq("test")
        end
    end

    describe "#new" do
        context "when field has a default value" do
            it "should be assigned a clone of that value at construction" do
                hash = {
                    "test" => 5
                }

                Person7 = Lyg::Model.define do
                    field :age do
                        default 0
                    end

                    field :dict do
                        default hash
                    end
                end

                person = Person7.new
                expect(person.age).to eq(0)
                expect(person.dict).to eq(hash)

                # Check that the original value will not be modified
                person.dict["test"] = 6
                expect(person.dict["test"]).to eq(6)
                expect(hash["test"]).to eq(5)
            end
        end
    end

    describe "#parse" do
        it "should parse a hash with all values correctly" do
            Person3 = Lyg::Model.define do
                field :name do
                end
            end
            hash = {
                "name" => "Test"
            }

            person = Person3.parse(hash)
            expect(person.name).to eq("Test")
        end

        context "when non-required field is missing value" do
            it "should equal nil" do
                Person4 = Lyg::Model.define do
                    field :name do
                    end
                end
                hash = {}

                person = Person4.parse(hash)
                expect(person.name).to eq(nil)
            end
        end

        context "when required field is missing value" do
            it "should raise SerializationError" do
                Person5 = Lyg::Model.define do
                    field :name do
                        required true
                    end
                end

                hash = {
                    "asd" => "Test"
                }
                expect do
                    Person5.parse(hash)
                end.to raise_error(Lyg::SerializationError)
            end
        end

        context "when field has a key different from its name" do
            it "should parse values from the key instead" do
                Person6 = Lyg::Model.define do
                    field :name do
                        key :first_name
                    end
                end
                hash = {
                    "first_name" => "Test"
                }

                person = Person6.parse(hash)
                expect(person.name).to eq("Test")
            end
        end
    end
end
