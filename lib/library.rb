# frozen_string_literal: true

class Library
  Entry = Struct.new(:key, :title, :icon, :badge, :empty, :matches, keyword_init: true) do
    # Return whether the entry is a smart feed rather than a feed.
    #
    # @return [Boolean] Whether the entry is keyed by a symbol, as only the smart feeds are.
    def smart?
      key.is_a?(Symbol)
    end
  end

  # Create a library of feeds.
  #
  # @param feeds [Array<Feed>] The feeds to list.
  # @param state [ReadState] What decides which articles are unread or starred.
  def initialize(feeds, state)
    @feeds    = feeds
    @state    = state
    @articles = []
  end

  # Return the articles that an entry lists.
  #
  # @param entry [Library::Entry] The entry whose articles to list.
  # @param hide_read [Boolean] Whether to leave out the articles that have been read.
  # @return [Array<Article>] The matching articles.
  def articles_for(entry, hide_read: false)
    @articles.select(&entry.matches).reject { |article| hide_read && @state.read?(article) }
  end

  # Return the count that the badge of each entry shows.
  #
  # The unread articles are found once and shared by every entry, since the
  # counts are refreshed after each article that is read.
  #
  # @param entries [Array<Library::Entry>] The entries to count for.
  # @return [Array<Integer>] The number of unread articles of each entry, or zero for an entry without a badge.
  def badge_counts(entries)
    unread  = @articles.reject { |article| @state.read?(article) }
    by_feed = unread.group_by(&:feed)

    entries.map { |entry| badge_for(entry, unread, by_feed) }
  end

  # Return the entries of the sidebar.
  #
  # The smart feeds come first, followed by the feeds alphabetically by their
  # current names.
  #
  # @return [Array<Library::Entry>] The entries.
  def entries
    feeds = @feeds.sort_by { |feed| feed.name.downcase }

    [today_entry, unread_entry, starred_entry, *feeds.map { |feed| feed_entry(feed) }]
  end

  # Return the article with an ID.
  #
  # @param id [String, nil] The ID of the article.
  # @return [Article] The article.
  # @return [nil] When no article has the ID.
  def find(id)
    @articles.find { |article| article.id == id }
  end

  # Load the articles of every feed, several feeds at a time.
  #
  # A refresh also looks for the icons of the feeds, which is rare since an
  # icon is kept for a week.
  #
  # @param refresh [Boolean] Whether to download the feeds whose cache is stale.
  # @param on_feed [#call, nil] Called with each feed and its articles as it is loaded, on a worker thread.
  # @yield [done, total] Called before the first feed and after each one, so progress can be shown.
  # @yieldparam done [Integer] How many feeds have been loaded.
  # @yieldparam total [Integer] How many feeds there are.
  # @return [Array<Article>] The articles, newest first, with undated ones last.
  def load(refresh:, on_feed: nil, &progress)
    progress&.call(0, @feeds.size)

    Chronology.newest_first(load_feeds(refresh, on_feed, progress).flatten(1))
  end

  # Swap in the freshly loaded articles of one feed, among those of the others.
  #
  # A refresh hands over a feed at a time, so that the sidebar can show its
  # icon and unread count without waiting for the rest. The state of articles
  # that are left out is not forgotten here, since feeds that have not been
  # handed over yet would then lose theirs. {#replace} does that once all feeds
  # are loaded.
  #
  # The articles of the others are already sorted, so each new article is
  # inserted at its place rather than sorting everything again for every feed.
  #
  # @param feed [Feed] The feed that was loaded.
  # @param articles [Array<Article>] The articles of the feed.
  # @return [void]
  def merge(feed, articles)
    others = @articles.reject { |article| article.feed.equal?(feed) }

    articles.select { |article| shown?(article) }.each { |article| Chronology.insert(others, article) }

    @articles = others
  end

  # Return the next feed after an entry that has unread articles.
  #
  # The search wraps around to the first feed, and starts there when the entry
  # is a smart feed. It is how reading moves on once a feed has been read.
  #
  # @param entries [Array<Library::Entry>] The entries of the sidebar.
  # @param current [Library::Entry] The entry being read.
  # @return [Library::Entry] The entry of the feed.
  # @return [nil] When no other feed has unread articles.
  def next_unread_entry(entries, current)
    feeds = entries.reject(&:smart?)
    start = feeds.index { |entry| entry.key == current.key } || -1

    feeds.rotate(start + 1).find { |entry| entry.key != current.key && unread_count(entry).positive? }
  end

  # Swap in a freshly loaded list of articles.
  #
  # Articles older than the window are left out, so a feed that is rarely
  # updated, or is very long, does not fill the lists with old articles. The
  # state of what is left out is forgotten in time.
  #
  # @param articles [Array<Article>] The articles to swap in.
  # @return [void]
  def replace(articles)
    @articles = articles.select { |article| shown?(article) }

    @state.prune(Set.new(@articles, &:id))
  end

  # Return how many articles of an entry are unread.
  #
  # @param entry [Library::Entry] The entry whose unread articles to count.
  # @return [Integer] The count.
  def unread_count(entry)
    articles_for(entry).count { |article| !@state.read?(article) }
  end

  private

  # Return the count that the badge of one entry shows.
  #
  # @param entry [Library::Entry] The entry to count for.
  # @param unread [Array<Article>] The unread articles.
  # @param by_feed [Hash{Feed => Array<Article>}] The unread articles of each feed.
  # @return [Integer] The number of unread articles, or zero for an entry without a badge.
  def badge_for(entry, unread, by_feed)
    if !entry.badge
      0
    elsif entry.smart?
      unread.count(&entry.matches)
    else
      by_feed.fetch(entry.key, []).size
    end
  end

  # Build the entry for one feed.
  #
  # @param feed [Feed] The feed to build an entry for.
  # @return [Library::Entry] The entry.
  def feed_entry(feed)
    Entry.new(key: feed, title: feed.name, badge: true, empty: "No articles.",
              matches: ->(article) { article.feed.equal?(feed) })
  end

  # Load the articles of one feed, and look for its icon when refreshing.
  #
  # @param feed [Feed] The feed to load.
  # @param refresh [Boolean] Whether to download the feed when its cache is stale.
  # @return [Array<Article>] The articles of the feed.
  def load_feed(feed, refresh)
    articles = feed.articles(refresh: refresh)

    if refresh
      feed.refresh_icon
    end

    articles
  end

  # Load every feed on a few threads, reporting each one as it finishes.
  #
  # The callbacks are called one at a time, so that they do not have to guard
  # against each other.
  #
  # @param refresh [Boolean] Whether to download the feeds whose cache is stale.
  # @param on_feed [#call, nil] Called with each feed and its articles.
  # @param progress [#call, nil] Called with how many feeds are done and how many there are.
  # @return [Array<Array<Article>>] The articles of each feed, in the order of the feeds.
  def load_feeds(refresh, on_feed, progress)
    done = 0
    lock = Mutex.new

    WorkerPool.map(@feeds, workers: FEED_FETCHERS) do |feed|
      load_feed(feed, refresh).tap do |loaded|
        lock.synchronize do
          on_feed&.call(feed, loaded)
          progress&.call(done += 1, @feeds.size)
        end
      end
    end
  end

  # Return whether an article is worth showing.
  #
  # @param article [Article] The article to check.
  # @return [Boolean] Whether the article has no date, is within the maximum age or is starred.
  def shown?(article)
    cutoff = Time.now - (ARTICLE_MAX_AGE_DAYS * 86_400)

    article.date.nil? || article.date >= cutoff || @state.starred?(article)
  end

  # Build the smart feed of starred articles.
  #
  # @return [Library::Entry] The entry.
  def starred_entry
    Entry.new(key: :starred, title: "Starred", icon: "starred-symbolic", badge: true, empty: "No starred articles.",
              matches: ->(article) { @state.starred?(article) })
  end

  # Return whether an article was published in the past day.
  #
  # @param article [Article] The article to check.
  # @return [Boolean] Whether the article has a date no older than a day.
  def today?(article)
    !article.date.nil? && article.date >= Time.now - TODAY_SECONDS
  end

  # Build the smart feed of articles published in the past day.
  #
  # The day is a rolling 24 hours rather than the calendar day, so that it does
  # not empty out at midnight.
  #
  # @return [Library::Entry] The entry.
  def today_entry
    Entry.new(key: :today, title: "Today", icon: "weather-clear-symbolic", badge: true,
              empty: "Nothing published today.", matches: method(:today?))
  end

  # Build the smart feed of articles that are not yet read.
  #
  # @return [Library::Entry] The entry.
  def unread_entry
    Entry.new(key: :unread, title: "All Unread", icon: "mail-unread-symbolic", badge: true, empty: "All caught up.",
              matches: ->(article) { !@state.read?(article) })
  end
end
