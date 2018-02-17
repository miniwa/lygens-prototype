require "json"
require "lygens/model/model"

module Lyg
    class ParserError < StandardError
    end

    # A parser capable of parsing ruby objects into model instances
    class ObjectParser
        def parse_as(class_type, raw)
            unless class_type < AbstractModel
                raise TypeError, "Model type expected"
            end

            object = transform_raw(raw)
            unless object.is_a?(Hash) || object.is_a?(Array)
                raise TypeError, "Invalid object type, hash or array expected"
            end

            return class_type.parse(object)
        end

        def transform_raw(raw)
            # Assumes the object is of array or hash-like type
            return raw
        end
    end

    # A parser capable of parsing json into model instances
    class JsonParser < ObjectParser
        def transform_raw(raw)
            begin
                return JSON.parse(raw)
            rescue JSON::ParserError => exc
                raise ParserError, "An error occured in the internal parser"
            end
        end
    end
end
