module Lyg
    class FourChanError < StandardError
    end

    class FourChanHttpError < FourChanError
    end

    class FourChanPostError < FourChanError
    end

    class FourChanBannedError < FourChanPostError
    end

    class FourChanCaptchaError < FourChanPostError
    end

    class FourChanTimeoutError < FourChanPostError
    end

    class FourChanArchivedError < FourChanPostError
    end
end
