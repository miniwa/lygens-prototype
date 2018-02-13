require "bundler/setup"
require "lygens"

client = Lyg::FourChanClient.new
thread_ids = client.get_threads("g")

cpu_threads = []
thread_ids.each do |thread_id|
    cpu_thread = Thread.new do
        thread = client.get_thread("g", thread_id.number)
        puts thread.op.number
        puts thread.op.comment
        puts thread.reply_count
    end

    cpu_threads.push(cpu_thread)
end

cpu_threads.each do |cpu_thread|
    cpu_thread.join
end
