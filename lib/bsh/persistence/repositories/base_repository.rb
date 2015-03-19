require 'abstractize'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
require 'bsh/persistence/errors/non_persisted_model_error'

module BSH
  module Persistence
    module Repositories
      # An abstract repository implementation with common functions
      class BaseRepository
        include Abstractize

        attr_reader :collection, :adapter, :model_class

        def initialize(adapter)
          @adapter = adapter
          class_name = self.class.name.demodulize
          model_class_name = class_name[/.*(?=Repository)/]
          @collection = model_class_name.underscore.pluralize.to_sym
          return if class_name == 'BaseRepository'
          @model_class = Models.const_get(model_class_name)
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
  end
end
