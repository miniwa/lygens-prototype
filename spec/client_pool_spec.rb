require "lygens/client_pool"
require "time"

RSpec.describe(Lyg::LygensClientPool) do
    before(:each) do
        @now = Time.now
        @pool = Lyg::LygensClientPool.new(20)
        @client1 = instance_double("Lyg::FourChanClient")
        @client2 = instance_double("Lyg::FourChanClient")
        @client3 = instance_double("Lyg::FourChanClient")
    end

    describe("#get_cool_client") do
        it "should return the client with the least recent timestamp" do
            @pool.add(@client1, @now - 40)
            @pool.add(@client2, @now - 30)
            @pool.add(@client3, @now - 10)

            expect(@pool.get_cool_client).to eq(@client1)
        end

        it "should give clients lacking timestamp priority" do
            @pool.add(@client1, @now - 40)
            @pool.add(@client2, @now - 30)
            @pool.add(@client3, nil)

            expect(@pool.get_cool_client).to eq(@client3)
        end

        it "should not return clients that are not properly cooled off" do
            @pool.add(@client1, @now - 18)
            expect(@pool.get_cool_client).to eq(nil)
        end
    end

    describe "#remove" do
        it "should remove given clients" do
            @pool.add(@client1)
            @pool.remove(@client1)
            expect(@pool.length).to eq(0)
        end
    end

    describe "#length" do
        it "should properly report length" do
            expect(@pool.length).to eq(0)
            @pool.add(@client1)
            expect(@pool.length).to eq(1)
        end
    end
end
