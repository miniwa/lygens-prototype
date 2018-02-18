module Lyg
    class FourChanError < StandardError
    end

    class FourChanPostError < FourChanError
    end

    class FourChanBannedError < FourChanPostError
    end

    class FourChanArchivedError < FourChanPostError
    end
end
