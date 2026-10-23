# frozen_string_literal: true

class FeedCache
  # Create the cache of one feed.
  #
  # @param url [String] The URL of the feed.
  def initialize(url)
    @path            = File.join(CACHE_DIR, "#{Digest::SHA256.hexdigest(url)[0, 16]}.xml")
    @validators_path = "#{@path.delete_suffix(".xml")}.yml"
  end

  # Return what the feed's server needs to know to leave out an unchanged feed.
  #
  # The server sent validators with the cached copy. Sent back as conditions on
  # the next request, they let the server answer that nothing changed, which
  # costs almost nothing, instead of sending the feed again.
  #
  # Some servers add `-gzip` to the ETag of a compressed response, and only
  # recognize the ETag again without it, so it is left off.
  #
  # @return [Hash{String => String}] The request headers, empty without a cached copy or validators.
  def conditional_headers
    if File.exist?(@path)
      saved = validators

      { "If-None-Match" => saved["etag"]&.sub(/-gzip"\z/, '"'), "If-Modified-Since" => saved["last_modified"] }.compact
    else
      {}
    end
  end

  # Return the cached XML.
  #
  # @return [String] The XML.
  # @return [nil] When nothing is cached.
  def read
    if File.exist?(@path)
      File.read(@path)
    end
  end

  # Return whether the cached copy is missing or old.
  #
  # @return [Boolean] Whether there is no cached copy, or it is older than the maximum age.
  def stale?
    !File.exist?(@path) || (Time.now - File.mtime(@path)) > CACHE_MAX_AGE
  end

  # Count the cached copy as new, because the server said it has not changed.
  #
  # @return [void]
  def touch
    FileUtils.touch(@path)
  end

  # Keep a response, with what the server said about how to recognize it.
  #
  # @param body [String] The XML.
  # @param meta [Hash{String => String}] The headers of the response, which can include `etag` and `last-modified`.
  # @return [void]
  def write(body, meta)
    FileUtils.mkdir_p(CACHE_DIR)
    File.write(@path, body)
    File.write(@validators_path,
               YAML.dump({ "etag" => meta["etag"], "last_modified" => meta["last-modified"] }.compact))
  end

  private

  # Return what the server said about how to recognize the cached copy.
  #
  # @return [Hash{String => String}] The `etag` and `last_modified` that were saved, or nothing if unreadable.
  def validators
    Hash(YAML.safe_load_file(@validators_path))
  rescue StandardError
    {}
  end
end
