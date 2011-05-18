require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/to_json'
require 'active_support/json/encoding'
require 'active_support/core_ext/string/output_safety'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class/inheritable_attributes'
require 'active_support/concern'

require 'mongoid/relations/proxy'

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
        self.data_table_options[:fields] ||= self.fields.dup.stringify_keys.keys.reject { |k| Mongoid.destructive_fields.include?(k) }
      end

      def data_table_searchable_fields
        self.data_table_options[:searchable] ||= self.data_table_fields
      end

      def data_table_sortable_fields
        self.data_table_options[:sortable] ||= self.data_table_fields
      end

      def to_data_table(controller, options = {}, &block)
        ::Mongoid::DataTable::Proxy.new(self, controller, options, &block)
      end

    end

  end
end