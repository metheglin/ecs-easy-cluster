require "ecs/easy/cluster/version"

require "ostruct"
require "aws-sdk"

require "ecs/easy/configure"
require "ecs/easy/instance"

# configure = Ecs::Easy::Configure.new do |c|
#   c.profile = ""
#   c.region = ""
# end
# instance = Ecs::Easy::Instance.new do |i|
#   i.type      = "t2.nano"
#   i.keypair   = "your-keypair"
#   i.azs       = "ap-northeast-1a,ap-northeast-1c"
#   i.subnets   = "subnet-00000000,subnet-11111111"
#   i.vpc       = "vpc-00000000"
#   i.image_id  = "ami-00000000"
#   i.security_group = "sg-00000000"
# end
# cluster = Ecs::Easy::Cluster::MemScale.new("cluster-name", configure) do |c|
#   c.max_instances = 2
#   c.min_instances = 1
#   c.instance = instance
# end
# cluster.make_task_running!("your-task-definition-name")

module Ecs
  module Easy
    module Cluster

      autoload :Base, File.expand_path("../cluster/base.rb", __FILE__)
      autoload :MemScale, File.expand_path("../cluster/mem_scale.rb", __FILE__)
      
    end
  end
end
