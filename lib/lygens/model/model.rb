require "lygens/model/error"
require "lygens/model/descriptor"

module Lygens
    # Holds the definition methods for the model dsl
    class Model
        def self.define(&block)
            model_descriptor = ModelDescriptor.new
            model_descriptor.instance_eval(&block)
            model_class = model_descriptor.class

            model_class.fields.each do |field|
                model_class.class_eval do
                    define_method(field.name.to_sym) do
                        return instance_variable_get("@#{field.name}")
                    end

                    define_method("#{field.name}=".to_sym) do |value|
                        instance_variable_set("@#{field.name}", value)
                    end
                end
            end

            return model_class
        end
    end

    # An abstrsct model that all dsl models inherit from
    # Handles the fields variable, parsing methods and variable initialization
    class AbstractModel
        def self.fields
            return @fields
        end

        def self.fields=(fields)
            @fields = fields
        end

        def self.parse(hash)
            model = new
            model.parse(hash)
            return model
        end

        def initialize
            self.class.fields.each do |field|
                send("#{field.name}=", field.default.clone)
            end
        end

        def parse(hash)
            self.class.fields.each do |field|
                value = nil
                if hash.key?(field.key.to_s)
                    value = hash[field.key.to_s]
                end

                if value.nil? && field.required
                    raise SerializationError, "Required field #{field.name}"\
                        " missing from hash"
                end
                send("#{field.name}=", value)
            end
        end
    end

    # Describes a field of a model in the model dsl
    class Field
        def initialize(name)
            @name = name
            @key = name
            @required = false
            @default = nil
        end

        attr_accessor :name, :key, :required, :default
    end
end
