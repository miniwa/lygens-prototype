require "time"

module Lyg
    # Maintains a list of four chan clients to use when accessing the api
    class LygensClientPool
        # Initializes the pool with a given timeout value in seconds
        def initialize(timeout)
            @client_timestamps = {}
            @timeout = timeout
            @lock = Concurrent::ReadWriteLock.new
        end

        def get_cool_client
            unless @client_timestamps.any?
                return nil
            end

            lacking_timestamp = @client_timestamps.select do |client, timestamp|
                timestamp.nil?
            end
            if lacking_timestamp.any?
                return lacking_timestamp.keys[0]
            end

            sorted = @client_timestamps.sort_by do |client, timestamp|
                timestamp
            end
            now = Time.now
            stamp = sorted[0][1]
            if stamp.nil? || (now - @timeout) > stamp
                return sorted[0][0]
            else
                return nil
            end
        end

        def set_timestamp(client, timestamp)
            @client_timestamps[client] = timestamp
        end

        def length
            return @client_timestamps.length
        end

        def remove(client)
            @client_timestamps.delete(client)
        end

        def add(client, timestamp = nil)
            @client_timestamps[client] = timestamp
        end
    end
end
