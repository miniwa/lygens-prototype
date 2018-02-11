require "lygens/http/response"

RSpec.describe Lyg::HttpResponse do
    before(:each) do
        @response = Lyg::HttpResponse.new(200)
    end

    describe "#new" do
        it "should assign the code given in construction" do
            expect(@response.code).to eq(200)
        end

        context "when given invalid status code" do
            it "should raise ArgumentError" do
                expect do
                    Lyg::HttpResponse.new(268)
                end.to raise_error(ArgumentError)
            end
        end
    end
    
    describe "#parse_as" do
        context "when called with content and parser" do
            it "it should parse the object" do
                obj = {"test" => 10}
                str = "{\"test\": 10}"
                @response.parser = instance_double("Lyg::ObjectParser")
                @response.content = str
                allow(@response.parser).to receive(:parse_as)
                    .and_return(obj)
                
                expect(@response.parse_as(String)).to eq(obj)
                expect(@response.parser).to have_received(:parse_as)
                    .with(String, str)
            end
        end

        context "when called without parser" do
            it "should raise ArgumentError" do
                expect do
                    @response.parse_as(String)
                end.to raise_error(ArgumentError)
            end
        end

        context "when called on a response lacking content" do
            it "should raise ArgumentError" do
                expect do
                    @response.parser = instance_double("Lyg::ObjectParser")
                    @response.parse_as(String)
                end.to raise_error(ArgumentError)
            end
        end
    end

    describe "#content" do
        it "should be assignable" do
            @response.content = "test"
            expect(@response.content).to eq("test")
        end
    end
end
