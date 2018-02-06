require "lygens/http/client"

RSpec.describe Lygens::Http::Client do
    before(:each) do
        @transport = double("Lygens::Http::Transport")
        @client = Lygens::Http::Client.new(@transport)
        @response = Lygens::Http::Response.new(200)
        @args = {
            url: "test.se",
            method: :get,
            headers: {},
            cookies: {}
        }
    end
    
    describe "#make_request" do
        context "when called with only url and method" do
            it "should call the transport with only those parameters" do
                allow(@transport).to receive(:make_request).and_return(@response)
                @client.make_request(@args)
                expect(@transport).to have_received(:make_request)
                    .with(@args)
            end
        end

        context "when called with preset header or cookie" do
            it "should include those headers or cookies in the request" do
                @client.headers[:host] = "google.se"
                @client.cookies[:cfid] = "test"
                allow(@transport).to receive(:make_request).and_return(@response)

                params = @args
                params[:headers][:host] = "google.se"
                params[:cookies][:cfid] = "test"
                
                @client.make_request(@args)

                expect(@transport).to have_received(:make_request)
                    .with(params)
            end
        end

        context "when called with both preset and argument headers or cookies" do
            it "should prioritize the argument" do
                @client.headers[:host] = "google.se"
                @client.cookies[:cfid] = "test"
                allow(@transport).to receive(:make_request).and_return(@response)

                params = @args
                params[:headers][:host] = "test.se"
                params[:cookies][:cfid] = "testtest"
                
                @client.make_request(params)
                expect(@transport).to have_received(:make_request)
                    .with(params)
            end
        end

        context "when autosave_cookies is enabled" do
            it "should automatically save cookies from the response" do
                @client.autosave_cookies = true
                @response.cookies[:id] = "test"
                allow(@transport).to receive(:make_request).and_return(@response)

                @client.make_request(@args)
                expect(@client.cookies.length).to eq(1)
                expect(@client.cookies[:id]).to eq("test")
            end
        end

        context "when called without url or method" do
            it "should raise ArgumentError" do
                allow(@transport).to receive(:make_request).and_return(@response)
                expect do
                    @client.make_request({ url: "test.se" })
                end.to raise_error(ArgumentError)

                expect do
                    @client.make_request({ method: :get })
                end.to raise_error(ArgumentError)
            end
        end
    end
end
