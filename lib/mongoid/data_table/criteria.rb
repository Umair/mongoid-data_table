module Mongoid
  module DataTable
    module Criteria
      # do nothing
    end
  end

  class Criteria

    # Used for chaining +Criteria+ scopes together in the for of class methods
    # on the +Document+ the criteria is for.
    #
    # Options:
    #
    # name: The name of the class method on the +Document+ to chain.
    # args: The arguments passed to the method.
    # block: Optional block to pass
    #
    # Returns: <tt>Criteria</tt>
    def method_missing(name, *args, &block)
      if @klass.respond_to?(name)
        @klass.send(:with_scope, self) do
          @klass.send(name, *args, &block)
        end
      else
        return entries.send(name, *args)
      end
    end

  end
end