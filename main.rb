require "bundler/setup"
require "lygens"

# Config
captcha_api_key = "11346f1d5172530024ab2dc6ea6dbe05"
fourchan_site_key = "6Ldp2bsSAAAAAAJ5uyx_lx34lJeEpTLVkP5k04qc"
fourchan_site = "https://boards.4chan.org/v"

# Clients
transport = Lyg::RestClientHttpTransport.new
client = Lyg::FourChanClient.new(transport, "host")
captcha_client = Lyg::AntiCaptchaClient.new(transport,
    captcha_api_key)

# Payload
board = "v"
thread_number = "407013593"
comment = "magic mod when"

thread = client.get_thread(board, thread_number)
puts "BOARD: /#{board}/"
puts "THREAD: #{thread.op.number}"
puts "REPLIES: #{thread.replies.length}"
puts "IMAGES: #{thread.image_count}"

puts "-"
puts "Creating captcha task.."
task_id = captcha_client.create_recaptcha_task(fourchan_site, fourchan_site_key)
puts "Task created (#{task_id})"

solved = false
answer = nil
while !solved
    puts "Sleeping 5 seconds.."
    sleep(5)
    puts "Fetching task status.."
    response = captcha_client.get_recaptcha_result(task_id)
    if response.is_ready
        answer = response.answer
        puts "Captcha solved. Answer: #{answer}"
        solved = true
    end
end

puts "Attempting to post #{comment}.."
response = client.post(board, thread_number, comment, answer)
puts "-"
puts "CODE: #{response.code}"
puts "HEADERS:"
response.headers.each do |key, value|
    puts "#{key}: #{value}"
end
puts "CONTENT: #{response.content}"
