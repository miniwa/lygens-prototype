require "lygens/model/model"

RSpec.describe Lygens::Model do
    describe "#define" do
        it "should create a model with the proper fields" do
            Person1 = Lygens::Model.define do
                field :name do
                    required true
                end

                field :age do
                    key :years_old
                end
            end

            name_field = Person1.fields[0]
            expect(name_field.name).to eq(:name)
            expect(name_field.key).to eq(:name)
            expect(name_field.required).to eq(true)

            age_field = Person1.fields[1]
            expect(age_field.name).to eq(:age)
            expect(age_field.key).to eq(:years_old)
            expect(age_field.required).to eq(false)
        end

        it "should have fields representing the definition"\
        " that are assignable" do
            Person2 = Lygens::Model.define do
                field :name do
                end
            end

            person = Person2.new
            person.name = "test"
            expect(person.name).to eq("test")
        end
    end

    describe "#parse" do
        it "should parse a hash with all values correctly" do
            Person3 = Lygens::Model.define do
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
                Person4 = Lygens::Model.define do
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
                Person5 = Lygens::Model.define do
                    field :name do
                        required true
                    end
                end

                hash = {
                    "asd" => "Test"
                }
                expect do
                    Person5.parse(hash)
                end.to raise_error(Lygens::SerializationError)
            end
        end

        context "when field has a key different from its name" do
            it "should parse values from the key instead" do
                Person6 = Lygens::Model.define do
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
