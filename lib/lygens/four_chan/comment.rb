module Lyg
    class FourChanComment
        QUOTE = />>\d+/
        
        # Returns whether given comment contains a quote
        def self.has_quote(comment)
            return QUOTE.match(comment) != nil
        end
        
        # Replaces all quotes in given comment with given quote number
        def self.replace_quotes(comment, number)
            return comment.gsub(QUOTE, ">>#{number}")
        end
    end
end
