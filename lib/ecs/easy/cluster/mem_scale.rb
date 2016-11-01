module Ecs::Easy::Cluster
  class MemScale < Base 

    def make_task_running!( task_definition, overrides={} )
      unless exists?
        raise "Failed to create the new cluster. You should check the CloudFormation events." unless up!
      end

      res = nil
      3.times do
        wait_until_ready
        res = run_task!( task_definition, overrides )

        if res.failures.empty?
          break
        else # Failure because some reasons
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
      end

      res
    end

    def acceptable_task?( task_definition )
      # It preserves 128MB for ecs-agent
      required_memory( task_definition ) <= current_instance_memory - (128*1024*1024)
    end

    private
      def required_memory( task_definition )
        res = client.describe_task_definition( task_definition: task_definition )
        container_mems = res.task_definition.container_definitions.map(&:memory)
        total_mem_mb = container_mems.inject(0){|sum,n| sum + n}
        total_mem_mb * 1024 * 1024 # byte
      end

      def current_instance_memory
        INSTANCE_TYPES[instance.type][:mem] * 1024 * 1024 * 1024 # byte
      end
  end
end
