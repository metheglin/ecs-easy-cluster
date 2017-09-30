module Ecs
  module Easy
    class Instance

      TEMPLATE_PATH = File.expand_path("../cluster/config/cloudformation_template.json", __FILE__)
      TEMPLATE_BODY = File.read( TEMPLATE_PATH )

      attr_accessor :type, 
        :keypair, 
        :azs, # availability zones
        :subnets, 
        :vpc, 
        :image_id, 
        :security_group,
        :user_data

      def initialize **params
        params.each do |k,v|
          self.send("#{k}=", v) if self.methods.include?(k)
        end
        yield( self ) if block_given?
      end

      def custom_user_data
        default_user_data = [
          "#!/bin/bash\n",
          "echo ECS_CLUSTER=",
          {
            "Ref" => "EcsCluster"
          },
          " >> /etc/ecs/ecs.config\n"
        ]
        default_user_data.concat(user_data)
      end

      def template_body
        return TEMPLATE_BODY if user_data.nil? or user_data.empty?
        body = JSON.parse( TEMPLATE_BODY )
        body["Resources"]["EcsInstanceLc"]["Properties"]["UserData"]["Fn::Base64"]["Fn::Join"][1] = custom_user_data
        body["Resources"]["EcsInstanceLcWithoutKeyPair"]["Properties"]["UserData"]["Fn::Base64"]["Fn::Join"][1] = custom_user_data
        return JSON.pretty_generate( body )
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
