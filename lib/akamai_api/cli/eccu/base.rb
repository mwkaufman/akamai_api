require "akamai_api/cli/command"
require "akamai_api/cli/eccu/entry_renderer"

module AkamaiApi::CLI::ECCU
  class Base < AkamaiApi::CLI::Command
    desc 'requests', 'Print the list of the last requests made to ECCU'
    method_option :content, :type => :boolean, :aliases => '-c',
                  :desc => 'Print request content too'
    def requests
      load_config
      requests = AkamaiApi::ECCURequest.all :verbose => options[:content]
      puts EntryRenderer.render requests
    rescue ::AkamaiApi::Unauthorized
      puts "Your login credentials are invalid."
    end

    desc 'last_request', 'Print the last request made to ECCU'
    method_option :content, :type => :boolean, :aliases => '-c',
                  :desc => 'Print request content too'
    def last_request
      load_config
      request = AkamaiApi::ECCURequest.last verbose: options[:content]
      puts EntryRenderer.new(request).render
    rescue ::AkamaiApi::Unauthorized
      puts "Your login credentials are invalid."
    end

    desc 'publish_xml path/to/request.xml john.com', 'Publish a request made in XML for the specified Digital Property (usually the Host Header)'
    long_desc 'Publish a request made in XML (ECCU Request Format) and apply it to the specified Digital Property (usually the Host Header)'
    method_option :property_type, :type => :string, :aliases => '-P',
                  :default => 'hostheader', :banner => 'type',
                  :desc => 'Type of enlisted properties'
    method_option :no_exact_match, :type => :boolean,
                  :desc => 'Do not do an exact match on property names'
    method_option :emails,   :type => :array,  :aliases => '-e',
                  :banner => "foo@foo.com bar@bar.com",
                  :desc => 'Email(s) to use to send notification on status change'
    method_option :notes, :type => :string, :aliases => '-n',
                  :default => "ECCU Request using AkamaiApi #{AkamaiApi::VERSION}"
    def publish_xml(source, property)
      load_config
      args = {
        :notes => options[:notes],
        :property_exact_match => !options[:no_exact_match],
        :property_type => options[:property_type],
        :emails => options[:emails]
      }
      id = AkamaiApi::ECCURequest.publish_file property, source, args
      puts "Request correctly published:"
      puts EntryRenderer.new(AkamaiApi::ECCURequest.find(id, :verbose => true)).render
    rescue ::AkamaiApi::Unauthorized
      puts "Your login credentials are invalid."
    rescue ::AkamaiApi::ECCU::InvalidDomain
      puts "You are not authorized to specify this digital property."
    rescue Savon::SOAPFault
      puts $!.message
    end
  end
end
