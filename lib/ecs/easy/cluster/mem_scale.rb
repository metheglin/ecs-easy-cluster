module Ecs::Easy::Cluster
  class MemScale < Base 

    class CannotStartTaskError < StandardError
      attr_reader :result
      def initialize( result )
        @result = result
      end

      def failures
        return nil unless result
        result.failures
      end

      def fail_reason
        return nil if failures.empty?
        reasons = failures.map {|f| f.reason }
        if reasons.include?( "RESOURCE:MEMORY" )
          return "RESOURCE:MEMORY"
        end
        nil
      end
    end

    EC2_PROFILE_PATH = File.expand_path("../config/ec2_profile.json", __FILE__)
    INSTANCE_TYPES = JSON.parse(File.read( EC2_PROFILE_PATH ))

    def make_task_running!( task_definition, overrides={} )
      unless exists?
        unless up!
          raise "Failed to create the new cluster. You should check the CloudFormation events."
        end
      end

      retry_count = 3
      begin
        wait_until_ready
        res = run_task!( task_definition, overrides )
        unless res.failures.empty?
          raise CannotStartTaskError.new( res )
        end
      rescue CannotStartTaskError => e
        puts e.failures
        case e.fail_reason
        when "RESOURCE:MEMORY"
          puts "No enough memory on current container instances to execute this task. Add another container instance automatically."

          if num_instances >= max_instances
            puts "Couldn\'t scale more instances because it reaches maximum instances. You should upgrade the maximum number of instance to execute multiple tasks at the same time."
          end
          unless acceptable_task?( task_definition )
            raise "Couldn\'t accept this task because of the lack of memory. You should upgrade ec2 instance type."
          end

          scale!
        else
          raise "Unknown reason: #{e.failures}"
        end

        puts "Failed to run the task. Try again."
        sleep 10
        retry_count -= 1
        retry if retry_count > 0
      rescue => e
        raise "Unknown reason: #{e}"
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
