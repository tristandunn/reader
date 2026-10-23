# frozen_string_literal: true

class Feed
  attr_reader :icon, :url

  attr_accessor :home_page, :image_url

  attr_writer :title

  class << self
    # Read the feeds listed in feeds.yml, which is created with defaults on
    # first run.
    #
    # @return [Array<Feed>] The feeds, or none when the file cannot be read.
    def load_all
      write_defaults unless File.exist?(CONFIG_PATH)
      Array(YAML.safe_load_file(CONFIG_PATH)).filter_map { |entry| from_entry(entry) }
    rescue StandardError => error
      warn "reader: cannot read #{CONFIG_PATH}: #{error.message}"
      []
    end

    private

    # Create a feed from an entry of feeds.yml.
    #
    # @param entry [String, Hash] A URL, or a hash with a `url` key.
    # @return [Feed] The feed.
    # @return [nil] When the entry has no URL.
    def from_entry(entry)
      url = entry
      url = entry["url"] if entry.is_a?(Hash)

      unless url.to_s.empty?
        new(url.to_s)
      end
    end

    # Create feeds.yml with the default feeds.
    #
    # @return [void]
    def write_defaults
      FileUtils.mkdir_p(File.dirname(CONFIG_PATH))
      File.write(CONFIG_PATH, DEFAULT_FEEDS)
    end
  end

  # Create a feed.
  #
  # @param url [String] The URL of the feed.
  def initialize(url)
    @url   = url
    @title = nil
    @cache = FeedCache.new(url)
    @icon  = FeedIcon.new(url)
  end

  # Load the articles of the feed.
  #
  # The articles come from the cache, which is refreshed first when it is stale
  # and a refresh was asked for.
  #
  # @param refresh [Boolean] Whether to download a stale feed.
  # @return [Array<Article>] The articles, or none when there is nothing to read.
  def articles(refresh:)
    xml = download if download?(refresh)
    xml ||= @cache.read

    if xml
      FeedParser.new(self).parse(xml)
    else
      []
    end
  end

  # Return the name that the sidebar and the article rows show.
  #
  # @return [String] The title of the feed itself, or its domain until the title is known.
  def name
    @title || domain
  end

  # Look for the icon of the feed, once the kept one is old.
  #
  # Nothing is looked for when the feed links to no home page and its URL is
  # too malformed to find its site from.
  #
  # @return [void]
  def refresh_icon
    page = home_page || site

    if page
      @icon.refresh(home_page: page, image_url: image_url)
    end
  end

  private

  # Return the domain of the URL, without a leading `www.`.
  #
  # @return [String] The domain, or the whole URL when it has none.
  def domain
    host = URI.parse(url).host.to_s.delete_prefix("www.")

    if host.empty?
      url
    else
      host
    end
  rescue URI::InvalidURIError
    url
  end

  # Fetch the feed and cache it.
  #
  # A server that has not changed the feed since the cached copy answers that
  # it has not, and the cached copy is then used.
  #
  # @return [String] The XML.
  # @return [nil] When the download fails.
  def download
    URI.parse(url).open(request_options) { |response| keep(response) }
  rescue StandardError => error
    failed(error)
  end

  # Return whether the feed should be downloaded.
  #
  # @param refresh [Boolean] Whether a refresh was asked for.
  # @return [Boolean] Whether a refresh was asked for and the cache is stale.
  def download?(refresh)
    refresh && @cache.stale?
  end

  # Handle a request that did not succeed.
  #
  # @param error [StandardError] What went wrong.
  # @return [String] The cached XML, when the server said it has not changed.
  # @return [nil] When the request failed for another reason.
  def failed(error)
    if not_modified?(error)
      @cache.touch
      @cache.read
    else
      warn "reader: #{name}: #{error.message}"
      nil
    end
  end

  # Cache a response.
  #
  # @param response [IO] The response, which carries its headers.
  # @return [String] The XML.
  def keep(response)
    body = response.read

    @cache.write(body, response.meta)
    body
  end

  # Return whether an error is the server saying the feed has not changed.
  #
  # @param error [StandardError] The error to check.
  # @return [Boolean] Whether it is a `304 Not Modified` answer.
  def not_modified?(error)
    error.is_a?(OpenURI::HTTPError) && error.io.status.first == "304"
  end

  # Return the options of the request.
  #
  # @return [Hash{Symbol => Object}] The timeouts, and the conditional headers.
  def request_options
    { open_timeout: 10, read_timeout: 30 }.merge(@cache.conditional_headers)
  end

  # Return the root of the site that the feed is on.
  #
  # @return [String] The URL of the root.
  # @return [nil] When the URL of the feed cannot be parsed or is not absolute.
  def site
    URI.join(url, "/").to_s
  rescue URI::Error
    nil
  end
end
