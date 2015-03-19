require 'rrepo/adapters/base'
require 'mongo'

module RRepo
  module Adapters
    # A mongodb adapter
    class Mongo < Base
      def initialize(options)
        db_name = options.delete(:db)
        @client = ::Mongo::Client.new(options.delete(:host), options)
        @db = @client[db_name]
      end

      def create(collection, model)
        @db[collection.to_s].insert(model.to_hash)
      end

      def update(collection, model)
        hash = model.to_hash
        @db[collection.to_s].update(id_query(hash.delete(:_id)), hash)
      end

      def delete(collection, model)
        id = model.to_hash[:_id]
        @db[collection.to_s].remove(id_query(id))
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

      protected

      def id_query(id)
        { _id: id }
      end
    end
  end
end
