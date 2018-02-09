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

    describe "#body" do
        it "should be assignable" do
            @response.body = "test"
            expect(@response.body).to eq("test")
        end
    end
end
