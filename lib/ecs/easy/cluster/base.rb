module Ecs::Easy::Cluster
  class Base

    attr_reader :name, :configure, :client
    attr_accessor :instance, :min_instances, :max_instances

    def initialize( name, configure )
      @name = name
      @configure = configure
      @client = Aws::ECS::Client.new(
        region: configure.region
      )
      yield( self ) if block_given?
    end

    # Check if the cluster exists
    def exists?
      cluster_names = client.list_clusters.cluster_arns.map do |arn|
        arn.split("/").last
      end
      cluster_names.include?( name )
    end

    # Check if all the container instances on the cluster are ready
    def ready?
      return false unless exists?
      instance_arns = client.list_container_instances(cluster: name).container_instance_arns
      instances = client.describe_container_instances(
        cluster: name,
        container_instances: instance_arns
      ).container_instances
      instances.all? {|i| i.status == "ACTIVE" }
    end

    # Check if the task exists on the cluster
    def task_exists?( task )
      task_arns = client.list_tasks(cluster: name).task_arns
      task_arns.include?( task )
    end

    def num_instances
      client.list_container_instances(cluster: name).container_instance_arns.length
    end

    # Wait until all the container instances ready
    def wait_until_ready( retry_count=30, sleep_sec=2 )
      retry_count.times do
        break if ready?
        sleep sleep_sec
      end
    end

    def wait_until_task_running( arn )
      raise "Task Not Found. Possibly the task is already stopped." unless task_exists?( arn )
      client.wait_until(:tasks_running, tasks: [arn])
    end

    def run_task!( task_definition, overrides={} )
      res = client.run_task(
        cluster: name,
        task_definition: task_definition,
        overrides: overrides
      )
    end

    def up!
      unless exists?
        cmd = <<-EOH
          ecs-cli up \
            --keypair #{instance.keypair} \
            --capability-iam \
            --size #{min_instances} \
            --instance-type #{instance.type} \
            --azs #{instance.azs} \
            --subnets #{instance.subnets} \
            --vpc #{instance.vpc} \
            --security-group #{instance.security_group} \
            --image-id #{instance.image_id}
        EOH
        puts cmd

        IO.popen( cmd, "r" ) do |pipe|
          while line = pipe.gets
            puts line
          end
        end
      end

      return exists?
    end

    def scale!
      size = (num_instances+1 <= max_instances) ? num_instances+1 : max_instances
      cmd = <<-EOH
        ecs-cli scale \
          --capability-iam \
          --size #{size}
      EOH
      puts cmd

      IO.popen( cmd, "r" ) do |pipe|
        while line = pipe.gets
          puts line
        end
      end

      # Check the scale completion every 2 seconds until max 30 times
      30.times do
        return true if num_instances == size
        sleep 2
      end

      return false
    end

    # Deregister some container instances if they are idling
    def shrink!
      cmd = <<-EOH
        ecs-cli scale \
          --capability-iam \
          --size #{min_instances}
      EOH
      puts cmd

      IO.popen( cmd, "r" ) do |pipe|
        while line = pipe.gets
          puts line
        end
      end
    end

    private
      def fail_reason( failures )
        reasons = failures.map {|f| f.reason }
        if reasons.include?( "RESOURCE:MEMORY" )
          return "RESOURCE:MEMORY"
        end
      end

  end
end
