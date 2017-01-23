# Ecs::Easy::Cluster

ecs-easy-cluster is a easy clustering tool for AWS ECS.
This tool focuses on executing tiny scripts, jobs or batches without considering the running environment.

## Installation

Add this line to your application's Gemfile:

    gem 'ecs-easy-cluster'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ecs-easy-cluster

## Usage

```
require "ecs-easy-cluster"

#
# Set basic info: credentials and region
#
configure = Ecs::Easy::Configure.new do |c|
  c.profile = "your-aws-profile"
  c.region = "your-aws-region"
end

#
# Define ec2 instance profile
#
instance = Ecs::Easy::Instance.new do |i|
  i.type      = "t2.nano"
  i.keypair   = "your-keypair"
  i.azs       = "ap-northeast-1a,ap-northeast-1c"
  i.subnets   = "subnet-00000000,subnet-11111111"
  i.vpc       = "vpc-00000000"
  i.image_id  = "ami-00000000"
  i.security_group = "sg-00000000"
end

# 
# Define the scale setting of your cluster
#
cluster = Ecs::Easy::Cluster::MemScale.new("cluster-name", configure) do |c|
  c.max_instances = 2
  c.min_instances = 1
  c.instance = instance
end

#
# Make your task running
#
cluster.make_task_running!("your-task-definition-name")

#
# Shrink your scaled instances
# ------------
# !! CAUTION !!
# This command terminates redundant instances even if some tasks are running on them.
#
cluster.shrink!
```

## Memo

ecs/easy/cluster/cloudformation_template.json.erb is refered from the link below.
https://github.com/aws/amazon-ecs-cli/blob/master/ecs-cli/modules/aws/clients/cloudformation/template.go
