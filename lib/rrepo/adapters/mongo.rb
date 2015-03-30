require 'rrepo/adapters/base'

module RRepo
  module Adapters
    # A mongodb adapter
    class Mongo < Base
      include ::Mongo

      attr_reader :db

      def initialize(options)
        db_name = options.delete(:db)
        @client = MongoClient.new(options.delete(:host), options)
        @db = @client[db_name]
      end

      def create(collection, model)
        @db[collection.to_s].insert(model.to_hash)
      end

      def update(collection, model)
        hash = model.to_hash
        @db[collection.to_s].update(id_query(model._id), hash)
      end

      def delete(collection, model)
        @db[collection.to_s].remove(id_query(model._id))
      end

      def all(collection)
        @db[collection.to_s].find
      end

      def find(collection, id)
        @db[collection].find(id_query(id))
      end

      def clear(collection)
        @db[collection].drop
      end

      def query(collection, &block)
        Query.new(@db[collection], &block)
      end

      # A Mongo Query object
      class Query
        def initialize(collection, &block)
          @collection = collection
          @query = [{}]
          instance_eval(&block) if block_given?
        end

        def where(condition)
          @query.last.merge!(condition)
          self
        end

        def or
          @query << {}
          self
        end

        def run
          if @query.size > 1
            @collection.find(:$or => @query)
          else
            @collection.find(@query.first)
          end
        end

        def to_hash
          @query
        end
      end

      protected

      def id_query(id)
        object_id = id.is_a?(BSON::ObjectId) ? id : BSON::ObjectId(id)
        { _id: object_id }
      end
    end
  end
end
