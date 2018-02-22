require "lygens/client_pool"
require "lygens/util"

RSpec.describe(Lyg::Util) do
    describe "#parse_proxy_lines" do
        it "should properly parse proxy lines" do
            str = "88.234.133.23:8080\n"\
            "88.234.13.23:\n"\
            ".234.133.23:NaN\n"\

            proxies = Lyg::Util.parse_proxy_lines(str)
            expect(proxies.length).to eq(1)
            expect(proxies[0].ip).to eq("88.234.133.23")
            expect(proxies[0].port).to eq(8080)
            expect(proxies[0].anonymous).to eq(false)
            expect(proxies[0].supports_https).to eq(false)
            expect(proxies[0].uri).to eq("http://88.234.133.23:8080")
        end
    end
end
