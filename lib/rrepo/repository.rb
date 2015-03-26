require 'abstractize'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
require 'rrepo/errors/non_persisted_model_error'

module RRepo
  # An abstract repository implementation with common functions
  class Repository
    include Abstractize

    class << self
      def collection(collection = nil)
        return @collection = collection if collection.present?
        @collection
      end

      def model_class_name(name = nil, &block)
        return @model_class_name = name if name.present?
        return @model_class_name = block if block_given?
        @model_class_name
      end
    end

    attr_reader :collection, :adapter

    def initialize(adapter)
      @adapter = adapter
      class_name = self.class.name.demodulize
      @collection = (self.class.collection || class_name.underscore).to_sym
    end

    def create(model)
      return model if model._id.present?
      id = adapter.create(collection, model)
      model._id = id
      model
    end

    def update(model)
      unless model._id.present?
        fail Errors::NonPersistedModelError, "#{model} is not persisted"
      end
      adapter.update(collection, model)
    end

    def delete(model)
      unless model._id.present?
        fail Errors::NonPersistedModelError, "#{model} is not persisted"
      end
      adapter.delete(collection, model)
    end

    def all
      result = adapter.all(collection)
      result.map(&method(:model_for))
    end

    def find(id)
      result = adapter.find(collection, id)
      model_for(result)
    end

    def clear
      adapter.clear(collection)
    end

    def query(&block)
      adapter.query(collection, &block)
    end

    def model_class(attributes = {})
      if self.class.model_class_name.respond_to?(:call)
        model_class_name = self.class.model_class_name.call(attributes)
      else
        model_class_name = (
          self.class.model_class_name || self.class.name.demodulize.singularize
        )
      end
      model_class_name.constantize
    end

    def model_for(attributes)
      model_class(attributes).new(attributes)
    end
  end
end
