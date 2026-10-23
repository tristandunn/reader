# frozen_string_literal: true

class FeedIcon
  # Create the icon of one feed.
  #
  # @param url [String] The URL of the feed.
  def initialize(url)
    @path = File.join(ICON_DIR, Digest::SHA256.hexdigest(url)[0, 16])
  end

  # Return the bytes of the kept icon.
  #
  # @return [String] The PNG.
  # @return [nil] When the icon has not been fetched, or none was found.
  def read
    data = File.binread(@path) if File.exist?(@path)

    unless data.to_s.empty?
      data
    end
  end

  # Look for the icon again once the kept one is old.
  #
  # An empty file is kept when no icon is found, so a feed without one is not
  # looked up on every refresh. A failure is only reported, because an icon is
  # never worth losing the articles of a refresh over.
  #
  # @param home_page [String] The URL of the site of the feed.
  # @param image_url [String, nil] The image that the feed names for itself.
  # @return [void]
  def refresh(home_page:, image_url:)
    if stale?
      candidates = IconLinks.candidates(page(home_page), home_page) + [image_url, IconLinks.favicon(home_page)].compact

      FileUtils.mkdir_p(ICON_DIR)
      keep(candidates.lazy.filter_map { |url| download(url) }.first.to_s)
    end
  rescue StandardError => error
    warn "reader: cannot find an icon for #{home_page}: #{error.message}"
  end

  private

  # Download one candidate icon.
  #
  # @param url [String] Where the icon is.
  # @return [String] The bytes of the image.
  # @return [nil] When it is not an image or cannot be downloaded.
  def download(url)
    ImageStore.read(url)
  rescue StandardError
    nil
  end

  # Write the icon beside its file and move it into place.
  #
  # The main thread reads the icon while a worker thread may be writing it, so
  # a read never sees half a file.
  #
  # @param data [String] The bytes of the icon, which are empty when none was found.
  # @return [void]
  def keep(data)
    File.binwrite("#{@path}.tmp", data)
    File.rename("#{@path}.tmp", @path)
  end

  # Download the start of a home page, which is where its icons are linked.
  #
  # @param url [String] The URL of the home page.
  # @return [String] The HTML, which is empty when it cannot be downloaded.
  def page(url)
    URI.parse(url).open(open_timeout: 10, read_timeout: 30) { |response| response.read(HOME_PAGE_MAX_BYTES).to_s }
  rescue StandardError
    ""
  end

  # Return whether the icon should be looked for again.
  #
  # @return [Boolean] Whether nothing is kept, or what is kept is older than the maximum age.
  def stale?
    !File.exist?(@path) || (Time.now - File.mtime(@path)) > ICON_MAX_AGE
  end
end
