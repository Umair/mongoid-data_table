require 'rails'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/to_json'
require 'active_support/json/encoding'
require 'active_support/core_ext/string/output_safety'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class/inheritable_attributes'

require 'mongoid/data_table/proxy'
require 'mongoid/data_table/version'

module Mongoid
  module DataTable

    extend ActiveSupport::Concern

    included do
      self.class_attribute :data_table_options
      self.data_table_options ||= {}
    end

    module ClassMethods

      def data_table_fields
        self.data_table_options[:fields] ||= []
      end

      def data_table_searchable_fields
        self.data_table_options[:searchable] ||= self.data_table_fields
      end

      def data_table_sortable_fields
        self.data_table_options[:sortable] ||= self.data_table_fields
      end

      def to_data_table(controller, options = {}, explicit_block = nil, &implicit_block) #fields, search_fields=nil, explicit_block=nil, &implicit_block)
        block = (explicit_block or implicit_block)

        DataTable::Proxy.new(self, controller, options, &block)
      end

    end

  end
end