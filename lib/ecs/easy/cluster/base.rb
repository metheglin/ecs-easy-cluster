module Ecs::Easy::Cluster
  class Base

    TEMPLATE_PATH = File.expand_path("../config/cloudFormation_template.json", __FILE__)
    TEMPLATE_BODY = File.read( TEMPLATE_PATH )

    attr_reader :name, :configure, :ecs_client, :stack_name, :cfn_client
    attr_accessor :instance, :min_instances, :max_instances

    def initialize( name, configure )
      @name = name
      @configure = configure
      @ecs_client = Aws::ECS::Client.new(
        region: configure.region,
        credentials: configure.credentials
      )
      @stack_name = configure.cfn_stack_name_prefix + name
      @cfn_client = Aws::CloudFormation::Client.new(
        region: configure.region,
        credentials: configure.credentials
      )

      # default
      @min_instances = 1
      @max_instances = 1

      yield( self ) if block_given?
    end

    # Check if the cluster exists
    # A cluster existence should be decided as cloudformation stack existence
    def exists?
      res = cfn_client.describe_stacks( stack_name: stack_name )
      return res.stacks.length > 0
    rescue => e
      return false
    end

    # Check if all the container instances on the cluster are ready
    def ready?
      return false unless exists?
      instance_arns = ecs_client.list_container_instances(cluster: name).container_instance_arns
      return false if instance_arns.nil? or instance_arns.empty?
      res = ecs_client.describe_container_instances(
        cluster: name,
        container_instances: instance_arns
      )
      # unless res.respond_to?("container_instances") or
      #   res.container_instances.nil?
      #   return false
      # end
      res.container_instances.all? {|i| i.status == "ACTIVE" }
    end

    # Check if the task exists on the cluster
    def task_exists?( task )
      task_arns = ecs_client.list_tasks(cluster: name).task_arns
      task_arns.include?( task )
    end

    def num_instances
      ecs_client.list_container_instances(cluster: name).container_instance_arns.length
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
      ecs_client.wait_until(:tasks_running, tasks: [arn])
    end

    def run_task!( task_definition, overrides={} )
      res = ecs_client.run_task(
        cluster: name,
        task_definition: task_definition,
        overrides: overrides
      )
    end

    def up!
      unless exists?
        ecs_client.create_cluster( cluster_name: name )

        params = instance.cfn_parameters( name, "AsgMaxSize" => min_instances.to_s)
        cfn_client.create_stack(
          stack_name: stack_name,
          template_body: TEMPLATE_BODY,
          parameters: params,
          capabilities: ["CAPABILITY_IAM"],
          on_failure: "DELETE",
        )
        cfn_client.wait_until(
          :stack_create_complete, 
          stack_name: stack_name
        )
      end

      return exists?
    end

    def destroy!
      cfn_client.delete_stack(stack_name: stack_name)
      cfn_client.wait_until(
        :stack_delete_complete, 
        stack_name: stack_name
      )
    end

    def scale!
      size = (num_instances+1 <= max_instances) ? num_instances+1 : max_instances

      params = instance.cfn_parameters( name, "AsgMaxSize" => size.to_s)
      cfn_client.update_stack(
        stack_name: stack_name,
        template_body: TEMPLATE_BODY,
        parameters: params,
        capabilities: ["CAPABILITY_IAM"],
      )
      cfn_client.wait_until(
        :stack_update_complete, 
        stack_name: stack_name
      )

      # Check the scale completion every 2 seconds until max 30 times
      30.times do
        return true if num_instances == size
        sleep 2
      end

      return false
    rescue Aws::Waiters::Errors::WaiterFailed => e
      puts e
    end

    # Deregister some container instances if they are idling
    # TODO: Support idling check of container instances
    def shrink!
      params = instance.cfn_parameters( name, "AsgMaxSize" => min_instances.to_s)
      cfn_client.update_stack(
        stack_name: stack_name,
        template_body: TEMPLATE_BODY,
        parameters: params,
        capabilities: ["CAPABILITY_IAM"],
      )
      cfn_client.wait_until(
        :stack_update_complete, 
        stack_name: stack_name
      )
    rescue Aws::Waiters::Errors::WaiterFailed => e
      puts e
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
