require 'spec_helper'
require 'rrepo/repository'

# Base repository specs
module RRepo
  describe Repository do
    it 'cannot be instanciated' do
      expect { Repository.new(:adapter) }.to raise_error(AbstractError)
    end

    before(:each) do
      stub_const('Test', Class.new)
    end

    describe '.new' do
      let(:repository) do
        class Tests < Repository
        end
        Tests.new(:adapter)
      end

      it 'sets the collection according to the class name' do
        expect(repository.collection).to eq(:tests)
      end

      it 'sets the model class according to the class name' do
        expect(repository.model_class).to eq(Test)
      end

      it 'requires a database adapter' do
        expect { repository.class.new }.to raise_error(ArgumentError)
      end
    end

    let(:new_model) { double('model', _id: nil, :_id= => nil) }
    let(:persisted_model) { double('model', _id: 'foo') }

    let(:repository) do
      class Tests < Repository
      end
      Tests.new(adapter)
    end

    describe '#create' do
      let(:adapter) { double('adapter', create: :test_id) }

      it 'returns the given model if it already has an id' do
        expect(repository.create(persisted_model)).to be(persisted_model)
      end

      it 'calls create on the adapter if no id is present' do
        expect(adapter).to receive(:create).with(
          repository.collection, new_model
        )
        repository.create(new_model)
      end

      it 'sets the id on a new model' do
        expect(new_model).to receive(:_id=).with(:test_id)
        repository.create(new_model)
      end

      it 'returns the new model' do
        expect(repository.create(new_model)).to be(new_model)
      end
    end

    describe '#update' do
      let(:adapter) { double('adapter', update: :true) }

      it 'raises an error if the given model is not persisted' do
        expect { repository.update(new_model) }.to raise_error(
          Errors::NonPersistedModelError
        )
      end

      it 'calls update on the adapter if the model is persisted' do
        expect(adapter).to receive(:update).with(
          repository.collection, persisted_model
        )
        repository.update(persisted_model)
      end
    end

    describe '#delete' do
      let(:adapter) { double('adapter', delete: :true) }

      it 'raises an error if the given model is not persisted' do
        expect { repository.delete(new_model) }.to raise_error(
          Errors::NonPersistedModelError
        )
      end

      it 'calls delete on the adapter if the model is persisted' do
        expect(adapter).to receive(:delete).with(
          repository.collection, persisted_model
        )
        repository.delete(persisted_model)
      end
    end

    let(:model_class) { double('Test', new: nil) }

    before(:each) do
      stub_const('Test', model_class)
    end

    let(:adapter) { double('adapter', find: { _id: 1, foo: :bar }) }

    describe '#all' do
      let(:adapter) do
        double(
          'adapter', all: [{ _id: 1, foo: :bar }, { _id: 2, bar: :baz }]
        )
      end

      it 'calls #all on the adapter' do
        expect(adapter).to receive(:all).with(repository.collection)
        repository.all
      end

      it 'coerces the results into instances of the model class' do
        allow(model_class).to receive(:new).and_return(:first, :second)
        expect(model_class).to receive(:new).with(
          _id: 1, foo: :bar
        )
        expect(model_class).to receive(:new).with(
          _id: 2, bar: :baz
        )
        expect(repository.all).to eq([:first, :second])
      end
    end

    describe '#find' do
      let(:adapter) { double('adapter', find: { _id: 1, foo: :bar }) }

      it 'calls #find on the adapter' do
        expect(adapter).to receive(:find).with(repository.collection, 1)
        repository.find(1)
      end

      it 'coerces the result into instances of the model class' do
        expect(model_class).to receive(:new).with(
          _id: 1, foo: :bar
        ).and_return(:result)

        expect(repository.find(1)).to eq(:result)
      end
    end

    describe '#clear' do
      it 'calls #clear on the adapter' do
        expect(adapter).to receive(:clear).with(repository.collection)
        repository.clear
      end
    end
  end
end
