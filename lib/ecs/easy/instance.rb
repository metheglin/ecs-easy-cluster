module Ecs
  module Easy
    class Instance

      attr_accessor :type, 
        :keypair, 
        :azs, # availability zones
        :subnets, 
        :vpc, 
        :image_id, 
        :security_group

      def initialize **params
        params.each do |k,v|
          self.send("#{k}=", v) if self.methods.include?(k)
        end
        yield( self ) if block_given?
      end

      # Generate the parameters for cloudformation
      def cfn_parameters( cluster_name, params={} )
        base_params = [
          {
            parameter_key: "EcsAmiId",
            parameter_value: image_id,
          },
          {
            parameter_key: "EcsInstanceType",
            parameter_value: type,
          },
          {
            parameter_key: "KeyName",
            parameter_value: keypair,
          },
          {
            parameter_key: "VpcId",
            parameter_value: vpc,
          },
          {
            parameter_key: "SubnetIds",
            parameter_value: subnets,
          },
          {
            parameter_key: "SecurityGroup",
            parameter_value: security_group,
          },
          {
            parameter_key: "EcsCluster",
            parameter_value: cluster_name,
          },
        ]
        params.each do |k,v|
          base_params << ({
            "parameter_key" => k,
            "parameter_value" => v,
          })
        end
        base_params
      end
      
    end
  end
end
