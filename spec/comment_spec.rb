require "lygens/four_chan/comment"

RSpec.describe Lyg::FourChanComment do
    describe "#has_quote" do
        it "should detect quotes" do
            expect(Lyg::FourChanComment.has_quote("hello")).to eq(false)
            expect(Lyg::FourChanComment.has_quote(">12372\nhi")).to eq(false)
            expect(Lyg::FourChanComment.has_quote(">>12372\nhi")).to eq(true)
        end
    end

    describe "#replace_quotes" do
        it "should replace all quotes in comment" do
            str = ">>407108910\n"\
                ">>4071084236\n"\
                ">buy game meat at market\n"\
                ">oi lad, can I see thy meat license there?"
            
            expected = ">>1000\n"\
                ">>1000\n"\
                ">buy game meat at market\n"\
                ">oi lad, can I see thy meat license there?"
            
            res = Lyg::FourChanComment.replace_quotes(str, 1000)
            expect(res).to eq(expected)
        end
    end
end
