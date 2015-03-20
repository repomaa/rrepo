require 'abstractize'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
require 'rrepo/errors/non_persisted_model_error'

module RRepo
  # An abstract repository implementation with common functions
  class Repository
    include Abstractize

    attr_reader :collection, :adapter, :model_class

    def initialize(adapter)
      @adapter = adapter
      class_name = self.class.name.demodulize
      @collection = class_name.underscore.to_sym
      return if class_name == 'Repository'
      @model_class = class_name.singularize.constantize
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
      result.map(&model_class.method(:new))
    end

    def find(id)
      result = adapter.find(collection, id)
      model_class.new(result)
    end

    def clear
      adapter.clear(collection)
    end
  end
end
