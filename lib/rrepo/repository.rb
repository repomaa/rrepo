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
      Enumerator.new do |y|
        loop do
          doc = result.next_document
          break if doc.nil?
          y << model_for(doc)
        end
      end
    end

    def find(id = nil, &block)
      # TODO: rewrite to make this db agnostic
      if block_given?
        result = adapter.query(collection, &block).run.next_document
      else
        result = adapter.find(collection, id).next_document
      end
      return if result.blank?
      model_for(result)
    end

    def clear
      adapter.clear(collection)
    end

    def find_all(&block)
      result = adapter.query(collection, &block).run
      Enumerator.new do |y|
        loop do
          doc = result.next_document
          break if doc.nil?
          y << model_for(doc)
        end
      end
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
