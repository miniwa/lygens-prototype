require "lygens/http/request"

RSpec.describe Lyg::HttpRequest do
    before(:each) do
    end

    describe "#new" do
        context "when given method and url" do
            it "should assign them to the correct fields" do
                request = Lyg::HttpRequest.new(:get, "test.se")
                expect(request.method).to eq(:get)
                expect(request.url).to eq("test.se")
            end
        end

        context "when given invalid method or url" do
            it "should raise ArgumentError" do
                expect do
                    Lyg::HttpRequest.new(:get, nil)
                end.to raise_error(ArgumentError)

                expect do
                    Lyg::HttpRequest.new(nil, "test.se")
                end.to raise_error(ArgumentError)
            end
        end
    end
end
