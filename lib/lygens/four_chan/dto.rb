require "lygens/model/model"

module Lyg
    FourChanPostDto = Model.define do
        # Thread
        field :thread_sticky do
            key :sticky
            default do
                next 0
            end
        end

        field :thread_closed do
            key :closed
            default do
                next 0
            end
        end

        field :thread_archived do
            key :archived
            default do
                next 0
            end
        end

        field :thread_archived_on do
            key :archived_on
        end

        field :thread_images do
            key :images
        end

        field :thread_replies do
            key :replies
        end

        field :thread_bump_limit do
            key :bumplimit
            default do
                next 0
            end
        end

        field :thread_image_limit do
            key :imagelimit
            default do
                next 0
            end
        end

        field :thread_last_modified do
            key :last_modified
        end

        field :thread_tag do
            key :tag
        end

        field :thread_semantic_url do
            key :semantic_url
        end

        # Post
        field :number do
            key :no
        end

        field :reply_to do
            key :resto
        end

        field :time
        field :name
        field :tripcode do
            key :trip
        end

        field :id
        field :capcode
        field :country_code do
            key :country
        end

        field :country_name
        field :subject do
            key :sub
        end

        field :comment do
            key :com
        end

        field :pass_since do
            key :since4pass
        end

        # File
        field :file_name do
            key :filename
        end

        field :file_renamed do
            key :tim
        end

        field :file_ext do
            key :ext
        end

        field :file_size do
            key :fsize
        end

        field :file_md5 do
            key :md5
        end

        field :file_deleted do
            key :filedeleted
            default do
                next 0
            end
        end

        field :file_spoiler do
            key :spoiler
            default do
                next 0
            end
        end
    end

    FourChanGetThreadDto = Model.define do
        field :posts do
            type FourChanPostDto
        end
    end

    FourChanThreadInfoDto = Model.define do
        field :number do
            key :no
        end
        
        field :last_modified
    end

    FourChanGetThreadsDto = Model.define do
        field :page
        field :threads do
            type FourChanThreadInfoDto
        end
    end
end
