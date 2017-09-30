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

```ruby
require "ecs/easy/cluster"

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
  # Currently user_data allows only /bin/bash
  i.user_data = [
    "echo 'xxxxxxxx' >> /home/ec2-user/.ssh/authorized_keys\n",
  ]
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
res = cluster.make_task_running!("your-task-definition-name")

# 
# You can call aws-sdk Aws::ECS::Client method with: cluster.ecs_client
# http://docs.aws.amazon.com/sdkforruby/api/Aws/ECS/Client.html
# 
task_arns = res["tasks"].map{|t| t["task_arn"]}
cluster.ecs_client.wait_until(:tasks_stopped, cluster: "cluster-name", tasks: task_arns) do |w|
  w.max_attempts = 100
  w.delay = 6
end

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
