require "lygens/four_chan/client"
require "lygens/four_chan/dto"
require "lygens/http/transport"
require "lygens/model/model"

RSpec.describe Lyg::FourChanClient do
    before(:each) do
        @transport = instance_double("Lyg::HttpTransport")
        @client = Lyg::FourChanClient.new(@transport)
        @response = Lyg::HttpResponse.new(200)
    end

    describe "#get_thread" do
        it "should be able to parse a well-formed response" do
            json = <<-JSON
            {"posts": [
                {
                    "no": 51971506,
                    "sticky": 1,
                    "closed": 1,
                    "now": "12/20/15(Sun)20:03:52",
                    "name": "Anonymous",
                    "com": "Test",
                    "filename": "RMS",
                    "ext": ".png",
                    "w": 450,
                    "h": 399,
                    "tn_w": 250,
                    "tn_h": 221,
                    "tim": 1450659832892,
                    "time": 1450659832,
                    "md5": "cEeDnXfLWSsu3+A/HIZkuw==",
                    "fsize": 299699,
                    "resto": 0,
                    "capcode": "mod",
                    "semantic_url": "the-g-wiki",
                    "replies": 2,
                    "images": 0,
                    "unique_ips": 1
                },
                {
                    "no": 51971507,
                    "now": "12/20/15(Sun)20:03:53",
                    "name": "Anonymous",
                    "com": "First",
                    "time": 1450659833,
                    "resto": 51971506
                },
                {
                    "no": 51971508,
                    "now": "12/20/15(Sun)20:03:54",
                    "name": "Anonymous",
                    "com": "Second",
                    "id": "hello",
                    "trip": "!asdasd",
                    "time": 1450659834,
                    "resto": 51971506,
                    "since4pass": 2015
                }
            ]}
            JSON

            @response.content = json
            allow(@transport).to receive(:execute).and_return(@response)

            thread = @client.get_thread("g", 51971506)
            expect(thread.sticky).to eq(true)
            expect(thread.closed).to eq(true)
            expect(thread.archived).to eq(false)
             expect(thread.archived_at).to eq(nil)
            expect(thread.reply_count).to eq(2)
            expect(thread.image_count).to eq(0)
            expect(thread.at_bump_limit).to eq(false)
            expect(thread.at_image_limit).to eq(false)
            expect(thread.tag).to eq(nil)
            expect(thread.semantic_url).to eq("the-g-wiki")
            
            expect(thread.op.number).to eq(51971506)
            expect(thread.op.reply_to).to eq(0)
            expect(thread.op.time).to eq(Time.at(1450659832))
            expect(thread.op.name).to eq("Anonymous")
            expect(thread.op.tripcode).to eq(nil)
            expect(thread.op.id).to eq(nil)
            expect(thread.op.comment).to eq("Test")
            expect(thread.op.pass_since).to eq(nil)
            expect(thread.replies.length).to eq(2)
            
            first = thread.replies[0]
            expect(first.number).to eq(51971507)
            expect(first.reply_to).to eq(51971506)
            expect(first.time).to eq(Time.at(1450659833))
            expect(first.name).to eq("Anonymous")
            expect(first.tripcode).to eq(nil)
            expect(first.id).to eq(nil)
            expect(first.comment).to eq("First")
            expect(first.pass_since).to eq(nil)

            second = thread.replies[1]
            expect(second.number).to eq(51971508)
            expect(second.reply_to).to eq(51971506)
            expect(second.time).to eq(Time.at(1450659834))
            expect(second.name).to eq("Anonymous")
            expect(second.tripcode).to eq("!asdasd")
            expect(second.id).to eq("hello")
            expect(second.comment).to eq("Second")
            expect(second.pass_since).to eq(2015)
        end
    end

    describe "#get_threads" do
        it "should be able to parse a well-formed response" do
            json = <<-JSON
            [
                {
                    "page": 1,
                    "threads": [
                        {"no":51971506, "last_modified": 1450659844},
                        {"no":64708352, "last_modified": 1518475875}
                    ]
                },
                {
                    "page": 2,
                    "threads": [
                        {"no":64705955, "last_modified": 1518475777},
                        {"no":64705835, "last_modified": 1518475773}
                    ]
                }
            ]
            JSON

            @response.content = json
            allow(@transport).to receive(:execute).and_return(@response)
            
            threads = @client.get_threads("g")
            expect(threads.length).to eq(4)
            expect(threads[0].number).to eq(51971506)
            expect(threads[0].last_modified).to eq(Time.at(1450659844))
            expect(threads[1].number).to eq(64708352)
            expect(threads[1].last_modified).to eq(Time.at(1518475875))
            expect(threads[2].number).to eq(64705955)
            expect(threads[2].last_modified).to eq(Time.at(1518475777))
            expect(threads[3].number).to eq(64705835)
            expect(threads[3].last_modified).to eq(Time.at(1518475773))
        end
    end
end
