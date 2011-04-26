require 'eloqua/api/service'
require 'eloqua/remote_object'

module Eloqua
  class Query

    delegate :api, :to => :remote_object

    attr_reader :collection, :remote_object, :conditions, :total_pages
    attr_internal :current_page, :query_started


    # The amount of time in seconds to wait before sending another request to Eloqua
    @@request_delay = 1

    cattr_accessor :queries_per_second

    # Create a new query to attach conditions to.
    #
    #     class Contact < Eloqua::Entity
    #       remote_type = api.remote_type('Contact')
    #     end
    #
    #     Eloqua::Query.new(Contact)
    #
    # @param [Eloqua::RemoteObject] or one of its descendants
    def initialize(remote_object)
      unless(remote_object.is_a?(Class) && Eloqua::RemoteObject >= remote_object)
        raise(ArgumentError, 'must provide an Eloqua::RemoteObject or one of its descendants')
      end

      @page = 1
      @limit = 200
      @collection = []
      @remote_object = remote_object
      @conditions = []
      @fields = nil
      @has_requested = false
    end

    
    ## CHAIN-ABLES they reset the has_requested? but do not clear the collection
    
    # Sets or gets limit
    #
    #     query.limit(5) # sets limit returns self
    #     query.limit # returns 5
    #
    # @param [Integer]
    # @return [self, Integer]
    def limit(value = nil); end

    # Sets or gets page
    #
    #     query.page(5) # sets limit returns self
    #     query.page # returns 5
    #
    # @param [Integer]
    # @return [self, Integer]
    #
    def page(value = nil); end

    # Sets or gets the array of fields to find. 
    # Can use a literal string or a symbol of a {Eloqua::RemoteObject#map mapped} attribute 
    #
    #     query.fields([:email, 'Date'])
    #     query.fields # returns [:email, 'Date']
    #
    # @see Eloqua::RemoteObject::map
    # @param [Array]
    # @return [self, Array]
    def fields(value = nil); end
    

    # This mess defines the limit and page getter/setter methods
    # when they are set they will also set #has_requested? to false
    [:fields, :limit, :page].each do |attr|
      class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        remove_method(:#{attr})
        def #{attr}(value = nil)
          if(value.nil?)
            @#{attr}
          else
            @has_requested = false
            @#{attr} = value
            self
          end
        end
      RUBY
    end

    
    # Adds a condition to the query; may be chained.
    #
    #     query.condition(:email, '=', 'value').condition('created_at', '>', '2011-04-20')
    #
    # @param [String, Symbol] field name
    # @param [String] operator can use: `[ =, !=, <, >, >=, <=]`
    # @param [String] value to search for
    # @return self
    def condition(field, operator, value)
      @conditions << {
        :field => field,
        :type => operator,
        :value => value
      }
      self
    end
    
    # Send the built request to eloqua
    #
    #     query.condition(:email, '=', '*') # wildcard
    #     query.request!
    #     query.collection # Array of results
    #     query.current_page # Current page
    #     query.total_pages # Number of pages
    #
    # @return self
    def request!
      return if has_requested?
      xml_query = api.builder do |xml|
        xml.eloquaType do
          xml.template!(:object_type, remote_object.remote_type)
        end
        xml.searchQuery(build_query)

        if(!fields.blank? && fields.is_a?(Array))
          fields.map! do |field|
            field = remote_object.eloqua_attribute(field)
          end
          xml.fieldNames do
            xml.template!(:array, fields)
          end
        end

        xml.pageNumber(page)
        xml.pageSize(limit)
      end

      result = api.request(:query, xml_query)
      @has_requested = true

      if(result[:entities])
        @total_pages = result[:total_pages].to_i
        result = result[:entities]
        if(result[:dynamic_entity].is_a?(Hash))
          result[:dynamic_entity] = [result[:dynamic_entity]]
        end
        newly_added = []
        result = result[:dynamic_entity]
        result.each do |entity|
          record_attrs = {}
          entity_id = entity[:id]
          entity[:field_value_collection][:entity_fields].each do |entity_attr|
            record_attrs[entity_attr[:internal_name]] = entity_attr[:value]
          end
          record_attrs[remote_object.primary_key] = entity_id
          record_object = remote_object.new(record_attrs, :remote)

          collection << record_object
          newly_added << record_object
        end
        newly_added
      else
        @total_pages = 0
        false
      end
    end
    

    # Has the request been made yet?
    #
    #     query.has_requested? # false
    #     query.condition(:email, '=', '*').request!
    #     query.has_requested? # true
    #
    # @return [Boolean]
    def has_requested?
      @has_requested
    end

    def each(&block)

    end

    def all

    end

    def each_page!(&block)

    end

    protected

    # Builds query from conditions
    # conditions are assembled by their field, type and then value as below
    #
    #     #{field}#{type}'#{value}'
    #
    # then joined by AND which acts more like an SQL "OR" in Eloqua
    def build_query
      conditions.inject([]) do |parts, cond|
        part = ""
        part << remote_object.eloqua_attribute(cond[:field])
        part << cond[:type]
        part << "'#{cond[:value]}'"
        parts << part
      end.join(" AND ")
    end


  end
end

