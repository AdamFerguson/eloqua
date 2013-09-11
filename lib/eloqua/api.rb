require 'savon'

require 'active_support/core_ext/class'
require 'active_support/concern'
require 'active_support/core_ext/module/delegation'

require 'eloqua/builder/xml'
require 'eloqua/exceptions'

module Eloqua

  class Api

    autoload :Service, 'eloqua/api/service'
    autoload :Action, 'eloqua/api/action'

    # The namespace for Eloqua Array objects
    XML_NS_ARRAY = 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'

    # WSDLs are from 7-16-2012
    WSDL = {
      :service => File.dirname(__FILE__) + '/wsdl/service.wsdl',
      :data =>  File.dirname(__FILE__) + '/wsdl/data.wsdl',
      :email =>  File.dirname(__FILE__) + '/wsdl/email.wsdl',
      :action =>  File.dirname(__FILE__) + '/wsdl/action.wsdl'
    }

    class << self

      delegate :define_builder_template, :to => Eloqua::Builder::Xml
      delegate :builder_template, :to => Eloqua::Builder::Xml
      delegate :builder_templates, :to => Eloqua::Builder::Xml

      attr_accessor :last_response, :soap_error, :http_error

      @@clients = {}

      def reset_clients
        @@clients = {}
      end

      def clients
        @@clients
      end

      # There are four currently supported wsdl types for eloqua
      # 1. Service
      # 2. Data
      # 3. Email
      # 4. External Action
      def client(type, &block)
        if(!Eloqua.user || !Eloqua.password)
          raise('Eloqua.user or Eloqua.password is not set see Eloqua.authenticate')
        end
        clients[type] = Savon.client do |globals|
          globals.wsdl WSDL[type]
          globals.ssl_version :SSLv3
          globals.namespaces({"xmlns:arr" => XML_NS_ARRAY})
          globals.element_form_default :qualified
          globals.wsse_auth [Eloqua.user, Eloqua.password]
          globals.log false
          instance_eval(&block) if block_given?
        end
      end

      def builder(&block)
        Eloqua::Builder::Xml.create(:namespace => :wsdl, &block)
      end

      def remote_type(name, type = 'Base', id = 0)
        {
          :name => name,
          :type => type,
          :id => id
        }
      end

      def request(type, name, soap_body = nil, &block)
        result = send_remote_request(type, name, soap_body, &block)

        self.last_response = result.to_xml if result.respond_to?(:to_xml)

        if(result)
          result = result.to_hash
          response_key = "#{name}_response".to_sym
          result_key = "#{name}_result".to_sym
          if(result.has_key?(response_key))
            result = result[response_key]
          end
          if(result.has_key?(result_key))
            result = result[result_key]
          end
        end
        result
      end

      # Sends remote request and returns a response object
      def send_remote_request(type, name, soap_body = nil, &block)
        @soap_error = nil
        @http_error = nil

        response = client(type, &block).call(name, message: soap_body)

        response_errors(response)
        response
      end

      def response_errors(response)
        raise response.soap_fault if response.soap_fault?
        raise response.http_error if response.http_error?
      end

    end
  end

end
