# frozen_string_literal: true

class MainWindow
  include Ui

  attr_reader :entry, :list, :reader, :sidebar

  # Build the window, listing the unread articles.
  #
  # @param application [Gtk::Application] The application the window belongs to.
  # @param library [Library] The feeds and articles to show.
  # @param state [ReadState] Where read and starred articles are recorded.
  def initialize(application, library, state)
    @library = library
    @state   = state
    @entries = library.entries
    @entry   = @entries.find { |entry| entry.key == :unread }
    @refresh = build_refresher(library)
    @window  = build(Gtk::ApplicationWindow, application, css: "reader-window", title: "Reader")
    @actions = ArticleActions.new(@window, state, on_change: method(:article_changed), timeline: -> { @list.timeline })
    build_ui
  end

  # Show the window.
  #
  # @return [void]
  def present
    @window.present
  end

  # Fetch the feeds off the main loop, then swap the results in.
  #
  # Nothing happens while an earlier fetch is still running.
  #
  # @return [void]
  def reload
    @refresh.start
  end

  private

  # Swap in newly loaded articles and rebuild the sidebar, since the names of
  # feeds may have changed.
  #
  # The icons need no attention here, since the sidebar showed each one again
  # as its feed was loaded.
  #
  # The article being read stays open, so a refresh does not interrupt reading.
  #
  # @param articles [Array<Article>] The newly loaded articles.
  # @return [void]
  def apply(articles)
    @library.replace(articles)
    @entries = @library.entries
    @entry   = @entries.find { |entry| entry.key == @entry.key } || @entries.first
    @sidebar.rebuild(@entries, @entry.key)
    refresh_entry
  end

  # Restyle what changed and refresh the counts and the toolbar.
  #
  # @param article [Article, nil] The article that changed, or nil when several did.
  # @return [void]
  def article_changed(article)
    if article
      @list.restyle(article)
    else
      @list.restyle_all
    end

    update_counts
    update_toolbar
  end

  # Build the article list beneath its header.
  #
  # @return [Gtk::Box] The column.
  def build_list_column
    @list_header = ListHeader.new(on_mark_all_read: -> { @commands.mark_all_read },
                                  on_toggle_read:   -> { refresh_entry })
    @list        = ArticleList.new(@state, menu: @actions.method(:menu), on_activate: @actions.method(:open_in_browser),
                                           on_select: method(:open_article))

    box(:vertical, 0, [@list_header.widget, @list.widget], css: "content-column", width_request: 300)
  end

  # Build the sidebar, the article list and the reading pane, side by side.
  #
  # @return [void]
  def build_panes
    @sidebar = Sidebar.new(state: @state, on_refresh: method(:reload), on_select: method(:show_entry))
    @window.child = pane(@sidebar.widget, pane(build_list_column, build_reader_column, 380), 230)
  end

  # Build the reading pane beneath its toolbar.
  #
  # @return [Gtk::Box] The column.
  def build_reader_column
    @reader  = ReaderPane.new(downloader: ImageDownloader.new)
    @toolbar = ReaderToolbar.new(-> { @commands })

    box(:vertical, 0, [@toolbar.widget, @reader.widget], css: "content-column")
  end

  # Build what refreshes the feeds, which shows its progress in the sidebar.
  #
  # @param library [Library] The feeds to refresh.
  # @return [Refresher] The refresher.
  def build_refresher(library)
    Refresher.new(library, on_articles: method(:apply), on_feed: method(:feed_loaded),
                           on_finish: -> { @sidebar.hide_progress },
                           on_progress: ->(done, total) { @sidebar.show_progress(done, total) })
  end

  # Build the panes and the shortcuts, and list the unread articles.
  #
  # The window has no title bar of its own, since each pane has a header.
  #
  # @return [void]
  def build_ui
    @window.set_default_size(1240, 780)
    @window.titlebar = build(Gtk::Box, :horizontal, 0, visible: false)
    build_panes
    @commands = Commands.new(@library, @actions, self)
    KeyController.new(@window, @commands)
    @sidebar.rebuild(@entries, @entry.key)
    show_entry(@entry)
  end

  # Show the icon and the unread count of a feed that has just been loaded.
  #
  # The article list is left alone until every feed is loaded, so that it does
  # not shift while it is being read.
  #
  # @param feed [Feed] The feed that was loaded.
  # @param articles [Array<Article>] The articles of the feed.
  # @return [void]
  def feed_loaded(feed, articles)
    @library.merge(feed, articles)
    @sidebar.refresh_icon(feed)
    @sidebar.counts = @library.badge_counts(@entries)
  end

  # Show an article in the reading pane and mark it as read.
  #
  # @param article [Article] The article to open.
  # @return [void]
  def open_article(article)
    @reader.show(article)

    if @state.read?(article)
      update_toolbar
    else
      @actions.mark_read(article, true)
    end
  end

  # List the articles of the current entry again, keeping the open article.
  #
  # @return [void]
  def refresh_entry
    open_id = @reader.article&.id

    @list.refresh(@library.articles_for(@entry, hide_read: @list_header.hide_read?), open_id)
    @reader.refresh(@library.find(open_id))
    update_counts
  end

  # List the articles of an entry and clear the reading pane.
  #
  # @param entry [Library::Entry] The sidebar entry to show.
  # @return [void]
  def show_entry(entry)
    @entry = entry
    @list.show(@library.articles_for(entry, hide_read: @list_header.hide_read?), entry.empty)
    @reader.show(nil)
    update_counts
    update_toolbar
  end

  # Refresh the badges of the sidebar and the name and unread count in the
  # header of the article list.
  #
  # @return [void]
  def update_counts
    @sidebar.counts = @library.badge_counts(@entries)
    @list_header.update(@entry.title, @list.timeline.unread_count)
  end

  # Match the toolbar of the reading pane to the article being read.
  #
  # @return [void]
  def update_toolbar
    article = @reader.article

    @toolbar.update(article, read:    !article.nil? && @state.read?(article),
                             starred: !article.nil? && @state.starred?(article))
  end
end
