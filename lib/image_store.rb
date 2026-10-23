# frozen_string_literal: true

module ImageStore
  module_function

  # Read an image from disk, or download it and keep it there.
  #
  # An image that is read from disk counts as recently used, which decides what
  # is removed when the images kept grow too large.
  #
  # @param url [String] Where the image is.
  # @return [String] The bytes of the image.
  # @return [nil] When the image cannot be downloaded.
  def fetch(url)
    path = File.join(IMAGE_DIR, Digest::SHA256.hexdigest(url)[0, 24])

    if File.exist?(path)
      FileUtils.touch(path)
      File.binread(path)
    else
      download(url, path)
    end
  rescue StandardError => error
    warn "reader: #{url}: #{error.message}"
    nil
  end

  # Download an image and keep it on disk.
  #
  # @param url [String] Where the image is.
  # @param path [String] Where to keep the image.
  # @return [String] The bytes of the image.
  def download(url, path)
    body = read(url)

    FileUtils.mkdir_p(IMAGE_DIR)
    File.binwrite(path, body)
    prune
    body
  end

  # Remove the images used least recently while the images kept are too large.
  #
  # @return [void]
  def prune
    files  = Dir[File.join(IMAGE_DIR, "*")].sort_by { |path| File.mtime(path) }
    excess = files.sum { |path| File.size(path) } - IMAGE_CACHE_MAX_BYTES

    files.each do |path|
      if excess.positive?
        excess -= File.size(path)
        File.delete(path)
      end
    end
  end

  # Read the bytes of an image.
  #
  # Anything but an image is refused, such as an error page that was sent with a
  # success status. An image over the size limit is refused too, rather than cut
  # short and kept in a state that never decodes.
  #
  # @param url [String] Where the image is.
  # @return [String] The bytes of the image.
  # @raise [RuntimeError] When the response is not an image, or is too large.
  def read(url)
    URI.parse(url).open(open_timeout: 10, read_timeout: 30) do |response|
      unless response.content_type.start_with?("image/")
        raise "not an image: #{response.content_type}"
      end

      # One byte more than the limit is read, to tell an image that fits from
      # one that was cut short.
      body = response.read(IMAGE_MAX_BYTES + 1).to_s.b

      if body.bytesize > IMAGE_MAX_BYTES
        raise "larger than #{IMAGE_MAX_BYTES} bytes"
      end

      body
    end
  end
end
