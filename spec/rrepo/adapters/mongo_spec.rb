require 'spec_helper'
# Defining this so the Mongo adapter can include it
module Mongo
end
require 'rrepo/adapters/mongo'

module RRepo
  # Specs for mongo adapter
  module Adapters
    describe Mongo do
      let(:mongo_driver) { Module.new }
      let(:model) { double('model', _id: 1, to_hash: { foo: :bar }) }
      let(:collection) { double('collection') }
      let(:db) { double('db', :[] => collection) }
      let(:mongo_client) do
        db = self.db
        Class.new do
          def initialize(_host, _options = {})
          end

          define_method(:[]) do |_|
            db
          end
        end
      end
      let(:adapter) { Mongo.new(host: 'foo') }

      before(:each) { stub_const('MongoClient', mongo_client) }

      describe '.new' do
        it 'creates a mongo client' do
          expect(mongo_client).to receive(:new).with(
            'foo', {}
          ).and_return(mongo_client.new('foo'))
          adapter
        end
      end

      describe '#create' do
        let(:model) { double('model', _id: 1, to_hash: { foo: :bar }) }
        it 'calls insert on the given collection with the attribute hash' do
          expect(collection).to receive(:insert).with(foo: :bar)
          adapter.create(:test, model)
        end
      end

      describe '#update' do
        it 'calls update on the collection with the attribute hash and id' do
          expect(collection).to receive(:update).with({ _id: 1 }, foo: :bar)
          adapter.update(:test, model)
        end
      end

      describe '#delete' do
        it 'calls remove on the collection with the id of the given model' do
          expect(collection).to receive(:remove).with(_id: 1)
          adapter.delete(:test, model)
        end
      end

      describe '#all' do
        it 'calls find with {} on the collection' do
          expect(collection).to receive(:find)
          adapter.all(:test)
        end
      end

      describe '#find' do
        it 'calls find on the collection with the id of the given model' do
          expect(collection).to receive(:find).with(_id: 1)
          adapter.find(:test, 1)
        end
      end

      describe '#clear' do
        it 'calls drop on the collection' do
          expect(collection).to receive(:drop)
          adapter.clear(:test)
        end
      end

      describe '#query' do
        it 'creates a new query object' do
          stub_const('RRepo::Adapters::Mongo::Query', double('Query'))
          expect(Mongo::Query).to receive(:new).with(collection)
          adapter.query(collection)
        end
      end

      describe Mongo::Query do
        describe '.new' do
          it 'requires a collection' do
            expect { Mongo::Query.new }.to raise_error(ArgumentError)
            Mongo::Query.new(collection)
          end
        end

        describe '.run' do
          let(:query) { Mongo::Query.new(collection) }

          it 'calls find on with the @query instance variable' do
            collection = double('collection')
            query_array = [{ foo: 'bar' }]
            query.instance_variable_set(:@collection, collection)
            query.instance_variable_set(:@query, query_array)
            expect(collection).to receive(:find).with(query_array.first)
            query.run
          end
        end
      end
    end
  end
end
