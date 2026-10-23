# frozen_string_literal: true

module WorkerPool
  module_function

  # Work through the queue until it is empty.
  #
  # @param queue [Thread::Queue] The closed queue of items and their indexes.
  # @param results [Array<Object>] Where each result is stored, at the index of its item.
  # @yield [item] Called for each item.
  # @yieldparam item [Object] The item to work on.
  # @return [void]
  def drain(queue, results)
    while (job = queue.pop)
      item, index    = job
      results[index] = yield(item)
    end
  end

  # Return a closed queue holding each item with its index.
  #
  # @param items [Array<Object>] The items to queue.
  # @return [Thread::Queue] The queue, which hands out nil once it is empty.
  def jobs(items)
    queue = Queue.new

    items.each_with_index { |item, index| queue << [item, index] }
    queue.close
  end

  # Run a block for each item on a few threads, and collect the results.
  #
  # Fetching feeds one after another waits on each server in turn, so a slow
  # server held up every feed after it. The threads spend that time waiting on
  # the network, which Ruby lets them do side by side.
  #
  # @param items [Array<Object>] The items to work on.
  # @param workers [Integer] The most threads to run at once.
  # @yield [item] Called on a worker thread for each item.
  # @yieldparam item [Object] The item to work on.
  # @return [Array<Object>] What the block returned for each item, in the order of the items.
  def map(items, workers:, &block)
    results = Array.new(items.size)
    queue   = jobs(items)

    Array.new([workers, items.size].min) { Thread.new { drain(queue, results, &block) } }.each(&:join)
    results
  end
end
