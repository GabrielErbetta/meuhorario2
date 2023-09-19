# Allows for concurrent run of a job
#   Spawn threads to run a method in every entry of a queue
module Concurrently
  # Spawns 'thread_number' threads to concurrently run a method
  def self.run(queue, thread_number, object, method_name)
    threads = []
    thread_number.times { threads << spawn_thread(queue, object, method_name) }
    threads.map(&:join)
  end

  # Spawns a thread that runs 'object.method_name' in the 'queue'
  def self.spawn_thread(queue, object, method_name)
    Thread.new do
      while (args = queue.pop(true))
        object.send(method_name, *args)
      end
    rescue ThreadError
      nil
    end
  end
end
