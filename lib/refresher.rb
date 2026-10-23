# frozen_string_literal: true

class Refresher
  # Create a refresher for the feeds of a library.
  #
  # The callbacks are called on the main loop, so that they can change widgets.
  #
  # @param library [Library] The feeds to refresh.
  # @param on_articles [#call] Called with the articles once all feeds are loaded.
  # @param on_feed [#call] Called with each feed and its articles as soon as that feed is loaded.
  # @param on_finish [#call] Called when the refresh has ended, whether or not it worked.
  # @param on_progress [#call] Called with how many feeds are done, and how many there are.
  def initialize(library, on_articles:, on_feed:, on_finish:, on_progress:)
    @library     = library
    @on_articles = on_articles
    @on_feed     = on_feed
    @on_finish   = on_finish
    @on_progress = on_progress
    @running     = false
  end

  # Fetch the feeds on another thread.
  #
  # Nothing happens while an earlier refresh is still running, since a second
  # one would only ask the servers for the same feeds again.
  #
  # @return [void]
  def start
    unless @running
      @running = true
      Thread.new { work }
    end
  end

  private

  # Hand a loaded feed over on the main loop.
  #
  # @param feed [Feed] The feed that was loaded.
  # @param articles [Array<Article>] The articles of the feed.
  # @return [void]
  def feed_loaded(feed, articles)
    on_main_loop { @on_feed.call(feed, articles) }
  end

  # Run the callback on the main loop, once.
  #
  # @yield What to run.
  # @return [void]
  def on_main_loop
    GLib::Idle.add do
      yield
      false # one-shot
    end
  end

  # Fetch the feeds and hand over the articles.
  #
  # The refresh is marked as finished on the main loop, which is the only place
  # that looks at the mark, even when fetching fails.
  #
  # @return [void]
  def work
    articles = @library.load(refresh: true, on_feed: method(:feed_loaded)) do |done, total|
      on_main_loop { @on_progress.call(done, total) }
    end

    on_main_loop { @on_articles.call(articles) }
  ensure
    on_main_loop do
      @running = false
      @on_finish.call
    end
  end
end
