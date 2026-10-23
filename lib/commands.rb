# frozen_string_literal: true

class Commands
  # Create the commands that the shortcuts and the toolbar buttons run.
  #
  # Each command is named after its action in {Shortcuts}. They only call on
  # the panes of the window, so how reading moves from one article to the next
  # can be tested without a display.
  #
  # @param library [Library] The feeds and articles.
  # @param actions [ArticleActions] What marks, stars and opens articles.
  # @param window [MainWindow] The window, which gives the panes and the entry being read.
  def initialize(library, actions, window)
    @library = library
    @actions = actions
    @window  = window
  end

  # Move the keyboard focus to the article list.
  #
  # @return [void]
  def focus_article_list
    @window.list.focus
  end

  # Move the keyboard focus to the sidebar.
  #
  # @return [void]
  def focus_sidebar
    @window.sidebar.focus
  end

  # Mark every article in the article list as read.
  #
  # @return [void]
  def mark_all_read
    @actions.mark_all_read(@window.list.timeline.articles)
  end

  # Mark every article in the article list as read, then move on to the next
  # feed with unread articles.
  #
  # @return [void]
  def mark_all_read_and_next_unread
    mark_all_read
    next_unread
  end

  # Mark the articles below the open one as read, which are the older ones.
  #
  # @return [void]
  def mark_older_read
    @actions.mark_below_read(article)
  end

  # Mark the open article as unread, then move on to the next unread article.
  #
  # @return [void]
  def mark_unread_and_next_unread
    if article
      @actions.mark_read(article, false)
    end

    next_unread
  end

  # Select the next entry of the sidebar.
  #
  # @return [void]
  def next_feed
    @window.sidebar.select_relative(1)
  end

  # Open the next unread article, moving on to the next feed with unread
  # articles once the article list has none left.
  #
  # @return [void]
  def next_unread
    following = @window.list.timeline.next_unread(article)

    if following
      @window.list.select(following)
    else
      next_unread_entry
    end
  end

  # Open the open article in the browser.
  #
  # @return [void]
  def open_in_browser
    @actions.open_in_browser(article)
  end

  # Select the previous entry of the sidebar.
  #
  # @return [void]
  def previous_feed
    @window.sidebar.select_relative(-1)
  end

  # Fetch the feeds again.
  #
  # @return [void]
  def reload
    @window.reload
  end

  # Scroll down a page, or move on to the next unread article at the end of
  # the open one.
  #
  # @return [void]
  def scroll_or_next_unread
    if @window.reader.more_below?
      @window.reader.scroll_page
    else
      next_unread
    end
  end

  # Mark the open article as read, or as unread when it is read.
  #
  # @return [void]
  def toggle_read
    @actions.toggle_read(article)
  end

  # Star the open article, or unstar it when it is starred.
  #
  # @return [void]
  def toggle_star
    @actions.toggle_star(article)
  end

  private

  # Return the article open in the reading pane.
  #
  # @return [Article] The article.
  # @return [nil] When no article is open.
  def article
    @window.reader.article
  end

  # Select the next feed with unread articles and open its first unread one.
  #
  # Selecting the feed lists its articles, so the article list is asked for its
  # timeline again afterward.
  #
  # @return [void]
  def next_unread_entry
    entry = @library.next_unread_entry(@library.entries, @window.entry)

    if entry
      @window.sidebar.select(entry.key)
      @window.list.select(@window.list.timeline.next_unread(nil))
    end
  end
end
