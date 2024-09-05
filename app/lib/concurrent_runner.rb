# Allows for concurrent run of a job
#   Spawn threads to run a method in every entry of a queue
class ConcurrentRunner
  # Initializes the object with a queue, the number of threads and a progress bar
  def initialize(queue: Queue.new, threads: 1)
    @queue = queue
    @thread_number = threads
    @progress_bar = ProgressBar.create(total: @queue.size, format: '%t: %B | %c / %C | %E')
  end

  # Spawns 'thread_number' threads to concurrently run a method of an object
  def run(object, method_name)
    threads = []

    @thread_number.times { threads << spawn_thread(object, method_name) }
    threads.map(&:join)
  end

  private

  # Spawns a thread that runs 'object.method_name' in the 'queue'
  def spawn_thread(object, method_name)
    dead_iterations = []

    Thread.new do
      while (args = @queue.pop(true))
        retries = 3

        begin
          object.send(method_name, *args)
          @progress_bar.increment
        rescue StandardError => e
          print_iteration_error(e, retries)
          retries -= 1

          if retries > 0
            sleep 10
            retry
          else
            dead_iterations << args_to_s(args)
          end
        end
      end
    rescue ThreadError
      puts "\n\nDEAD ITERATIONS: #{dead_iterations.pretty_inspect}\n\n" if dead_iterations.any?
    end
  end

  def print_iteration_error(error, retries)
    puts "====> Error in thread ##{Thread.current.object_id}! [#{retries} retries remaining]"
    puts error.message
  end

  def args_to_s(args)
    args.map! do |arg|
      case arg
      when ApplicationRecord
        "#{arg.class}[#{arg.id}]"
      else arg.to_s
      end
    end

    args.join(', ')
  end
end
