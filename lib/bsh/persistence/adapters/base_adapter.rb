require 'abstractize'

module BSH
  module Persistence
    module Adapters
      # An abstract adapter class
      class BaseAdapter
        include Abstractize

        def initialize(_options)
        end

        define_abstract_method :create
        define_abstract_method :update
        define_abstract_method :delete
        define_abstract_method :all
        define_abstract_method :find
        define_abstract_method :clear
      end
    end
  end
end
