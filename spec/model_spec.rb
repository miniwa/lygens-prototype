require "lygens/model/model"

RSpec.describe Lyg::Model do
    describe "#define" do
        it "should create a model with the proper fields" do
            Name = Lyg::Model.define do
                field :first_name
                field :last_name
            end

            Person1 = Lyg::Model.define do
                field :name do
                    required true
                    type Name
                end

                field :age do
                    key :years_old
                    default do
                        next 0
                    end
                end

                field :email
            end

            name_field = Person1.fields[0]
            expect(name_field.name).to eq(:name)
            expect(name_field.key).to eq(:name)
            expect(name_field.required).to eq(true)
            expect(name_field.default).to eq(nil)
            expect(name_field.type).to eq(Name)

            age_field = Person1.fields[1]
            expect(age_field.name).to eq(:age)
            expect(age_field.key).to eq(:years_old)
            expect(age_field.required).to eq(false)
            expect(age_field.default).to eq(0)
            expect(age_field.type).to eq(nil)

            email_field = Person1.fields[2]
            expect(email_field.name).to eq(:email)
            expect(email_field.key).to eq(:email)
            expect(email_field.required).to eq(false)
            expect(email_field.default).to eq(nil)
            expect(email_field.type).to eq(nil)
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

        context "when field is assigned a non-model type" do
            it "should raise TypeError" do
                expect do
                    Lyg::Model.define do
                        field :name do
                            type String
                        end
                    end
                end.to raise_error(TypeError)
            end
        end
    end

    describe "#new" do
        context "when field has a default value" do
            it "should be assigned a clone of that value at construction" do
                hash = {
                    "test" => {
                        "test" => 1
                    }
                }

                Person7 = Lyg::Model.define do
                    field :age do
                        default do
                            next 0
                        end
                    end

                    field :dict do
                        default do
                            next {"test" => {"test" => 1}}
                        end
                    end
                end

                person = Person7.new
                expect(person.age).to eq(0)
                expect(person.dict).to eq(hash)

                # Check that the original value will not be modified
                person.dict["test"]["test"] = 2
                expect(person.dict["test"]["test"]).to eq(2)

                person2 = Person7.new
                expect(person2.dict["test"]["test"]).to eq(1)
            end
        end
    end

    describe "#parse" do
        it "should parse a hash with all values correctly" do
            Person3 = Lyg::Model.define do
                field :name
            end
            hash = {
                "name" => "Test"
            }

            person = Person3.parse(hash)
            expect(person.name).to eq("Test")
        end

        it "should parse a list of objects" do
            Person8 = Lyg::Model.define do
                field :name
            end

            list = [
                {"name" => "Test"},
                {"name" => "Test2"}
            ]

            persons = Person8.parse(list)
            expect(persons[0].name).to eq("Test")
            expect(persons[1].name).to eq("Test2")
        end

        context "when called with a model containing nested models" do
            it "should recursively parse those model" do
                Name1 = Lyg::Model.define do
                    field :first_name
                    field :last_name
                end

                Person11 = Lyg::Model.define do
                    field :name do
                        type Name1
                    end
                    field :age
                end

                Company = Lyg::Model.define do
                    field :name
                    field :ceo do
                        type Person11
                    end
                end

                hash = {
                    "name" => "TestCompany",
                    "ceo" => {
                        "name" => {
                            "first_name" => "Boss",
                            "last_name" => "Smith"
                        },
                        "age" => 45
                    }
                }

                company = Company.parse(hash)
                expect(company.name).to eq("TestCompany")
                expect(company.ceo.name.first_name).to eq("Boss")
                expect(company.ceo.name.last_name).to eq("Smith")
                expect(company.ceo.age).to eq(45)
            end
        end

        context "when given an object that is not a Hash or an Array" do
            it "should raise TypeError" do
                Person9 = Lyg::Model.define do
                    field :name
                end

                expect do
                    Person9.parse("asdas")
                end.to raise_error(TypeError)
            end
        end

        context "when non-required field is missing value" do
            it "should equal nil" do
                Person4 = Lyg::Model.define do
                    field :name
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
