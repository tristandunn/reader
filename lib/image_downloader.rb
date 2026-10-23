# frozen_string_literal: true

class ImageDownloader
  # Start the workers that download images.
  #
  # Downloading an image per thread would start dozens at once for an article
  # full of images, so a few workers take them from a queue instead.
  #
  # @param workers [Integer] How many images to download at once.
  def initialize(workers: IMAGE_DOWNLOADERS)
    @queue   = Queue.new
    @threads = Array.new(workers) { Thread.new { work } }
  end

  # Queue the download of an image.
  #
  # @param url [String] Where to download the image from.
  # @param still_wanted [#call] Called when a worker is free, so an image whose article has been closed is skipped.
  # @yield [data] Called on a worker thread once the download has finished or failed.
  # @yieldparam data [String, nil] The bytes of the image.
  # @return [void]
  def fetch(url, still_wanted:, &block)
    @queue << [url, still_wanted, block]
  end

  private

  # Download an image and pass it to the block that asked for it.
  #
  # A block that raises is reported, so that it does not stop the worker.
  #
  # @param url [String] Where to download the image from.
  # @param block [Proc] The block that asked for the image.
  # @return [void]
  def deliver(url, block)
    block.call(ImageStore.fetch(url))
  rescue StandardError => error
    warn "reader: #{url}: #{error.message}"
  end

  # Download the queued images one at a time, for as long as the process lives.
  #
  # @return [void]
  def work
    loop do
      url, still_wanted, block = @queue.pop

      deliver(url, block) if still_wanted.call
    end
  end
end
