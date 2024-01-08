# Allows for concurrent run of a job
#   Spawn threads to run a method in every entry of a queue
class ConcurrentRunner
  # Initializes the object with a queue, the number of threads and a progress bar
  def initialize(queue: Queue.new, threads: 1)
    @queue = queue
    @thread_number = threads
    @progress_bar = ProgressBar.create(total: @queue.size)
  end

  # Spawns 'thread_number' threads to concurrently run a method of an object
  def run(object, method_name)
    threads = []

    @thread_number.times { threads << spawn_thread(object, method_name) }
    threads.map(&:join)
  end

  # Spawns a thread that runs 'object.method_name' in the 'queue'
  def spawn_thread(object, method_name)
    retries = 3

    Thread.new do
      while (args = @queue.pop(true))
        object.send(method_name, *args)
        @progress_bar.increment
      end
    rescue Net::OpenTimeout
      retries -= 1

      if retries > 0
        sleep 10
        retry
      end
    rescue ThreadError
      nil
    end
  end
end
