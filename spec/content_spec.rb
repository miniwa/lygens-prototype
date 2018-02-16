require "lygens/http/content"

RSpec.describe Lyg::HttpJsonContent do
    before(:each) do
        @content = Lyg::HttpJsonContent.new
    end
    
    describe "#as_test" do
        it "should returns its buffer as json" do
            @content.buffer = [1, 2, 3]
            expect(@content.as_text).to eq("[1,2,3]")
        end
    end
end
