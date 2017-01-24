module Ecs::Easy::Cluster
  class MemScale < Base 

    EC2_PROFILE_PATH = File.expand_path("../config/ec2_profile.json", __FILE__)
    INSTANCE_TYPES = JSON.parse(File.read( EC2_PROFILE_PATH ))

    def make_task_running!( task_definition, overrides={} )
      unless exists?
        unless up!
          raise "Failed to create the new cluster. You should check the CloudFormation events."
        end
      end

      res = nil
      3.times do
        wait_until_ready
        res = run_task!( task_definition, overrides )
        break if res.failures.empty?
        puts "Failed to run the task. Try again."
        sleep 5
      end

      # Failure because some reasons
      unless res.failures.empty?
        puts res.failures
        case fail_reason(res.failures)
        when "RESOURCE:MEMORY"
          puts "No enough memory on current container instances to execute this task. Add another container instance automatically."

          if num_instances >= max_instances
            raise "Could\'t scale more instances because it reaches maximum instances. You should upgrade the maximum number of instance to execute multiple tasks at the same time."
          end
          unless acceptable_task?( task_definition )
            raise "Could\'t accept this task because of the lack of memory. You should upgrade ec2 instance type."
          end

          scale!
        else
          raise "Unknown reason: #{res.failures}"
        end
      end

      res
    end

    def acceptable_task?( task_definition )
      # It preserves 128MB for ecs-agent
      required_memory( task_definition ) <= current_instance_memory - (128*1024*1024)
    end

    private
      def required_memory( task_definition )
        res = ecs_client.describe_task_definition( task_definition: task_definition )
        container_mems = res.task_definition.container_definitions.map(&:memory)
        total_mem_mb = container_mems.inject(0){|sum,n| sum + n}
        total_mem_mb * 1024 * 1024 # byte
      end

      def current_instance_memory
        INSTANCE_TYPES[instance.type]["mem"] * 1024 * 1024 * 1024 # byte
      end
  end
end
