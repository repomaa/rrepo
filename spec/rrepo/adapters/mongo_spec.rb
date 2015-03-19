require 'spec_helper'
require 'rrepo/adapters/mongo'

module RRepo
  # Specs for mongo adapter
  module Adapters
    describe Mongo do
      let(:model) { double('model', to_hash: { _id: 1, foo: :bar }) }
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
      before(:each) { stub_const('Mongo::Client', mongo_client) }

      describe '.new' do
        it 'creates a mongo client' do
          expect(mongo_client).to receive(:new).with(
            'foo', {}
          ).and_return(mongo_client.new('foo'))
          adapter
        end
      end

      describe '#create' do
        let(:model) { double('model', to_hash: { foo: :bar }) }
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
    end
  end
end
