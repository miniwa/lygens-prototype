require "lygens/model/error"
require "lygens/model/descriptor"

module Lyg
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

        # Parses an object or a list of objects depending on input
        # Raises TypeError if object is not a +Hash+ or +Array+
        def self.parse(object)
            if object.is_a?(Hash)
                model = new
                model.parse(object)
                return model
            elsif object.is_a?(Array)
                result = []
                object.each do |hash|
                    model = new
                    model.parse(hash)
                    result.push(model)
                end

                return result
            else
                raise TypeError, "Invalid type, hash or array expected"
            end
        end

        def initialize
            self.class.fields.each do |field|
                value = field.default
                send("#{field.name}=", value)
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

        # Returns the default value for this field
        def default
            if @default_block.nil?
                return nil
            end
            
            return @default_block.call()
        end

        attr_accessor :name, :key, :required, :default_block
    end
end
