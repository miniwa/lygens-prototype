require "lygens/http/client"
require "lygens/http/transport"
require "lygens/http/response"
require "lygens/model/model"
require "lygens/four_chan/dto"
require "time"

module Lyg
    # Represents a client for 4chan.org.
    class FourChanClient < HttpClient
        def initialize(transport = RestClientHttpTransport.new,
                host = "http://a.4cdn.org")
            @host = host
            super(transport)
        end

        def get_thread(board, number)
            url = @host + "/#{board}/thread/#{number}.json"
            request = HttpRequest.new(:get, url)
            response = @transport.execute(request)
            response.parser = JsonParser.new

            dto = response.parse_as(FourChanGetThreadDto)
            thread = parse_thread(dto.posts[0])
            thread.op = parse_post(dto.posts[0])
            1.upto(thread.reply_count) do |i|
                thread.replies.push(parse_post(dto.posts[i]))
            end

            return thread
        end

        def get_threads(board)
            url = @host + "/#{board}/threads.json"
            request = HttpRequest.new(:get, url)
            response = @transport.execute(request)
            response.parser = JsonParser.new

            pages = response.parse_as(FourChanGetThreadsDto)
            threads = []
            pages.each do |page|
                page.threads.each do |thread|
                    threads.push(parse_thread_info(thread))
                end
            end

            return threads
        end

        def parse_thread(post)
            thread = FourChanThread.new
            thread.sticky = post.thread_sticky == 1
            thread.closed = post.thread_closed == 1
            thread.archived = post.thread_archived == 1
            if thread.archived
                thread.archived_at = Time.at(post.thread_archived_on)
            end

            thread.at_bump_limit = post.thread_bump_limit == 1
            thread.at_image_limit = post.thread_image_limit == 1
            thread.reply_count = post.thread_replies
            thread.image_count = post.thread_images
            thread.tag = post.thread_tag
            thread.semantic_url = post.thread_semantic_url

            return thread
        end

        def parse_thread_info(thread_dto)
            thread_info = FourChanThreadInfo.new
            thread_info.number = thread_dto.number
            thread_info.last_modified = Time.at(thread_dto.last_modified)

            return thread_info
        end

        def parse_post(post_dto)
            post = FourChanPost.new
            post.number = post_dto.number
            post.reply_to = post_dto.reply_to
            post.time = Time.at(post_dto.time)
            post.name = post_dto.name
            post.tripcode = post_dto.tripcode
            post.id = post_dto.id
            post.comment = post_dto.comment
            post.pass_since = post_dto.pass_since

            return post
        end
    end

    # Represents a post in a 4chan thread
    class FourChanPost
        attr_accessor :number, :reply_to, :time, :name, :tripcode, :id,
            :comment, :pass_since
    end

    # Represents a thread on a 4chan board
    class FourChanThread
        def initialize
            @replies = []
            super
        end

        attr_accessor :sticky, :closed, :archived, :archived_at, :op, :replies,
            :reply_count, :image_count, :at_bump_limit, :at_image_limit, :tag,
            :semantic_url
    end

    # Represents identification info about a 4chan thread
    class FourChanThreadInfo
        attr_accessor :number, :last_modified
    end
end
