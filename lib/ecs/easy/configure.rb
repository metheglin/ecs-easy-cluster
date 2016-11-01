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
        params.each do |k,v|
          self.send("#{k}=", v) if self.methods.include?(k)
        end
        yield( self ) if block_given?
      end

    end
  end
end
