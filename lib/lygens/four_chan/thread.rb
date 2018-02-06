module Lygens
    module FourChan
        class Thread
            attr_accessor :sticky, :closed, :archived, :archived_at, :subject, :replies,
                :images, :bump_limit, :image_limit, :tag, :semantic_url, :unique_posters
        end
    end
end
