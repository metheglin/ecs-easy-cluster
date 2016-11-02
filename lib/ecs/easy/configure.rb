module Ecs
  module Easy
    class Configure

      attr_accessor :profile, 
        :access_key, 
        :secret_key, 
        :region, 
        :compose_project_name_prefix, 
        :compose_service_name_prefix, 
        :cfn_stack_name_prefix

      def initialize **params
        @compose_project_name_prefix  = ""
        @compose_service_name_prefix  = "ecscompose-service-"
        @cfn_stack_name_prefix        = "amazon-ecs-cli-setup-"

        params.each do |k,v|
          self.send("#{k}=", v) if self.methods.include?(k)
        end
        yield( self ) if block_given?
      end

      def credentials
        @credentials ||= profile ?
          Aws::SharedCredentials.new( profile_name: profile ) :
          Aws::Credentials.new( access_key, secret_key )
        @credentials
      end

    end
  end
end
