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
      
    end
  end
end
