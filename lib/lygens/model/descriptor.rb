# Used as evaluation proxy when defining a model
class ModelDescriptor
    def initialize
        @class = Class.new(AbstractModel)
        @class.fields = []
    end

    def field(name, &block)
        field_descriptor = Lygens::FieldDescriptor.new(name)
        field_descriptor.instance_eval(&block)
        @class.fields.push(field_descriptor.field)
    end

    attr_reader :class
end

# Used as evaluation proxy when defining a field within a model
class FieldDescriptor
    def initialize(name)
        @field = Field.new(name)
    end

    def required(value)
        @field.required = value
    end

    def key(value)
        @field.key = value
    end

    attr_reader :field
end
