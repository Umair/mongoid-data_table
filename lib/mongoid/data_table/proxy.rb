module Mongoid
  module DataTable
    class Proxy < ::Mongoid::Relations::Proxy

      attr_reader :klass, :controller, :options, :block, :params, :criteria, :unscoped, :fields, :aliases

      def initialize(klass, controller, options = {}, &block)
        @klass      = klass
        @controller = controller
        @options    = klass.data_table_options.merge(options)
        @block      = block

        @params   = options[:params]   || controller.params.dup
        @criteria = options[:criteria] || klass.scoped
        @unscoped = options[:unscoped] || klass.unscoped
        @fields   = options[:fields]   || klass.data_table_fields
        @aliases  = options[:aliases]  || @fields
      end

      def collection(force = false)
        reload if force
        @collection ||= conditions.paginate({
          :page => current_page,
          :per_page => per_page
        })
      end

      def reload
        (@collection = nil).nil?
      end

      ## pagination options ##

      def current_page
        params[:page].present? ? params[:page].to_i : (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0)+1
      end

      def per_page
        (params[:iDisplayLength] || klass.per_page rescue 10).to_i
      end

      def conditions
        criteria.order_by(order_by_conditions).where(filter_conditions).where(filter_field_conditions)
      end

      def to_hash(&inline_block)
        inline_block = block || default_data_table_block unless block_given?
        {
          :sEcho => params[:sEcho].to_i,
          :iTotalRecords => unscoped.count,
          :iTotalDisplayRecords => conditions.count,
          :aaData => collection.map do |object|
            data = controller.instance_eval { inline_block[object] }
            data.inject(data.is_a?(Hash) ? {} : []) do |result, item|
              Rails.logger.silence do
                controller.instance_eval(&render_data_table_block(klass, item, object, result))
              end
            end
          end
        }
      end

      def to_json(*args)
        to_hash.to_json
      end

      protected

      def order_by_conditions
        order_params = params.select { |k,v| k =~ /(i|s)Sort(Col|Dir)_\d+/ }
        return options[:order_by] || [] if order_params.blank?
        order_params.select { |k,v| k =~ /iSortCol_\d+/ }.sort_by(&:first).map do |col,field|
          i = /iSortCol_(\d+)/.match(col)[1]
          [ fields[field.to_i], order_params["sSortDir_#{i}"] || :asc ]
        end
      end

      def filter_conditions
        return unless (query = params[:sSearch]).present?

        {"$or" => klass.data_table_searchable_fields.map { |field| { field => /#{query}/i} } }
      end

      def filter_field_conditions
        order_params = params.select { |k,v| k =~ /sSearch_\d+/ }.inject({}) do |h,(k,v)|
          i = /sSearch_(\d+)/.match(k)[1]

          field_name = fields[i.to_i]
          field = klass.fields[field_name]
          field_type = field.respond_to?(:type) ? field.type : String

          query = params["sSearch_#{i}"]

          h[field_name] = (if [ Array, String, Symbol ].include?(field_type)
              begin
                Regexp.new(query)
              rescue RegexpError
                Regexp.new(Regexp.escape(query))
              end
            else
              query
            end) if query.present?
          h
        end
      end

      private

      def default_data_table_block
        lambda do |object|
          Hash[aliases.map { |c| [ aliases.index(c), object.send(c) ] }].merge(:DT_RowId => object._id)
        end
      end

      def render_data_table_block(klass, item, object, result = [])
        data_table = self
        lambda do |base|
          if result.is_a?(Hash)
            result.store(*(item.map do |value|
              self.instance_eval(&data_table.send(:render_data_table_block, klass, value, object, ''))
            end))
          else
            result << render_to_string(:inline => item.to_s, :locals => { :"#{klass.name.underscore}" => object, :object => object })
          end
          result
        end
      end

      def method_missing(method, *args, &block) #:nodoc:
        collection.send(method, *args, &block)
      end

    end
  end
end