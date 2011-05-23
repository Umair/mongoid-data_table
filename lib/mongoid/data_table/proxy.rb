module Mongoid
  module DataTable
    class Proxy < ::Mongoid::Relations::Proxy

      attr_reader :klass, :controller, :options, :extension, :params, :criteria, :unscoped, :fields, :aliases

      def initialize(klass, controller, options = {}, &block)
        @klass      = klass
        @controller = controller
        @options    = klass.data_table_options.merge(options)
        @extension  = block || klass.data_table_dataset || default_data_table_dataset

        @params   = options[:params]   || (controller.params.dup rescue {})
        @criteria = options[:criteria] || klass.criteria
        @unscoped = options[:unscoped] || klass.unscoped
        @fields   = options[:fields]   || klass.data_table_fields
        @aliases  = options[:aliases]  || @fields
      end

      def collection(force = false)
        reload if force
        @collection ||= conditions.page(current_page).per(per_page)
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
        inline_block = extension unless block_given?
        {
          :sEcho => params[:sEcho].to_i,
          :iTotalRecords => unscoped.count,
          :iTotalDisplayRecords => conditions.count,
          :aaData => collection.map do |object|
            data = controller.instance_eval { inline_block.call(object) }
            data.inject(data.is_a?(Hash) ? {} : []) do |result, item|
              Rails.logger.silence do
                controller.instance_eval(&render_data_table_block(klass, item, object, result))
              end
            end
          end
        }
      end

      def as_json(options = nil, &inline_block)
        to_hash(&inline_block).to_json(options)
      end

      def to_json(*args, &inline_block)
        as_json(*args, &inline_block)
      end

      protected

      def order_by_conditions
        order_params = params.dup.select { |k,v| k =~ /(i|s)Sort(Col|Dir)_\d+/ }
        return options[:order_by] || [] if order_params.blank?
        order_params.select { |k,v| k =~ /iSortCol_\d+/ }.sort_by(&:first).map do |col,field|
          i = /iSortCol_(\d+)/.match(col)[1]
          [ fields[field.to_i], order_params["sSortDir_#{i}"] || :asc ]
        end
      end

      def filter_conditions
        return unless (query = params[:sSearch]).present?

        b_regex = Boolean.set(params["bRegex"])

        {
          "$or" => klass.data_table_searchable_fields.map { |field|
            { field => (b_regex === true) ? data_table_regex(query) : query }
          }
        }
      end

      def filter_field_conditions
        params.dup.select { |k,v| k =~ /sSearch_\d+/ }.inject({}) do |h,(k,v)|
          i = /sSearch_(\d+)/.match(k)[1]

          field_name = fields[i.to_i]
          #field = klass.fields.dup[field_name]
          #field_type = field.respond_to?(:type) ? field.type : Object

          query = params["sSearch_#{i}"]
          b_regex = Boolean.set(params["bRegex_#{i}"])

          h[field_name] = (b_regex === true) ? data_table_regex(query) : query if query.present?
          h
        end
      end

      private

      def default_data_table_dataset
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

      def data_table_regex(query)
        Regexp.new(query, Regexp::IGNORECASE)
      rescue RegexpError
        Regexp.new(Regexp.escape(query), Regexp::IGNORECASE)
      end

      def method_missing(method, *args, &block) #:nodoc:
        collection.send(method, *args, &block)
      end

    end
  end
end