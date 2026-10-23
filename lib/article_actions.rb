# frozen_string_literal: true

class ArticleActions
  NAMES = {
    "copy-url"        => :copy_url,
    "mark-above-read" => :mark_above_read,
    "mark-below-read" => :mark_below_read,
    "open"            => :open_in_browser,
    "toggle-read"     => :toggle_read,
    "toggle-star"     => :toggle_star
  }.freeze

  # Register the actions of the menu on the window.
  #
  # @param window [Gtk::ApplicationWindow] The window to add the actions to.
  # @param state [ReadState] Where read and starred articles are recorded.
  # @param on_change [#call] Called after a change with the article that changed, or nil when several did.
  # @param timeline [#call] Called to get the {Timeline} of the article list, which marking above and below acts on.
  def initialize(window, state, on_change:, timeline:)
    @window    = window
    @state     = state
    @timeline  = timeline
    @on_change = on_change
    @target    = nil
    NAMES.each { |name, handler| add_action(name, handler) }
  end

  # Copy the link of an article to the clipboard.
  #
  # @param article [Article, nil] The article, where nil does nothing.
  # @return [void]
  def copy_url(article)
    link = link_of(article)

    unless link.empty?
      @window.display.clipboard.set(link)
    end
  end

  # Mark the articles listed above an article as read.
  #
  # @param article [Article, nil] The article to mark above, which marks nothing when absent.
  # @return [void]
  def mark_above_read(article)
    mark_all_read(@timeline.call.above(article))
  end

  # Mark every article in a list as read.
  #
  # An article that is already read keeps the day it was read, which decides
  # when its state is forgotten.
  #
  # @param articles [Array<Article>] The articles to mark.
  # @return [void]
  def mark_all_read(articles)
    articles.reject { |article| @state.read?(article) }.each { |article| @state.mark_read(article, true) }
    changed(nil)
  end

  # Mark the articles listed below an article as read.
  #
  # @param article [Article, nil] The article to mark below, which marks nothing when absent.
  # @return [void]
  def mark_below_read(article)
    mark_all_read(@timeline.call.below(article))
  end

  # Mark an article as read or as unread.
  #
  # @param article [Article] The article to mark.
  # @param read [Boolean] Whether the article should be read.
  # @return [void]
  def mark_read(article, read)
    @state.mark_read(article, read)
    changed(article)
  end

  # Build the right-click menu for an article.
  #
  # The actions of the menu apply to that article until the next menu is built.
  #
  # @param article [Article] The article that was clicked.
  # @return [Gio::Menu] The menu.
  def menu(article)
    @target = article
    root = Gio::Menu.new

    sections(article).each { |section| root.append_section(nil, section) }
    root
  end

  # Open the link of an article in the default browser.
  #
  # @param article [Article, nil] The article, where nil does nothing.
  # @return [void]
  def open_in_browser(article)
    link = link_of(article)

    unless link.empty?
      Gtk::UriLauncher.new(link).launch(@window, nil) { |_launcher, _result| nil }
    end
  end

  # Mark an article as unread when it is read, and as read otherwise.
  #
  # @param article [Article, nil] The article, where nil does nothing.
  # @return [void]
  def toggle_read(article)
    if article
      mark_read(article, !@state.read?(article))
    end
  end

  # Star an article, or unstar it when it is starred.
  #
  # @param article [Article, nil] The article, where nil does nothing.
  # @return [void]
  def toggle_star(article)
    if article
      @state.toggle_star(article)
      changed(article)
    end
  end

  private

  # Register one action on the window.
  #
  # @param name [String] The name of the action.
  # @param handler [Symbol] The name of the method that runs the action.
  # @return [void]
  def add_action(name, handler)
    action = Gio::SimpleAction.new(name)

    action.signal_connect("activate") { send(handler, @target) }
    @window.add_action(action)
  end

  # Save the state and tell the window what changed.
  #
  # @param article [Article, nil] The article that changed, or nil when several did.
  # @return [void]
  def changed(article)
    @state.save
    @on_change.call(article)
  end

  # Return the link of an article.
  #
  # @param article [Article, nil] The article whose link to return, which can be missing.
  # @return [String] The link, which is empty without an article.
  def link_of(article)
    article&.link.to_s
  end

  # Return the text of the menu item that marks an article as read or unread.
  #
  # @param article [Article] The article that the menu item marks.
  # @return [String] The text.
  def read_text(article)
    if @state.read?(article)
      "Mark as Unread"
    else
      "Mark as Read"
    end
  end

  # Build one section of the menu.
  #
  # @param items [Hash{String => String}] The text of each item, by the name of its action.
  # @return [Gio::Menu] The section.
  def section(items)
    menu = Gio::Menu.new

    items.each { |action, text| menu.append(text, action) }
    menu
  end

  # Build the sections of the menu, which are separated by lines.
  #
  # @param article [Article] The article that was clicked.
  # @return [Array<Gio::Menu>] The sections.
  def sections(article)
    [
      section("win.toggle-read" => read_text(article), "win.toggle-star" => star_text(article)),
      section("win.mark-above-read" => "Mark Above as Read", "win.mark-below-read" => "Mark Below as Read"),
      section("win.open" => "Open in Browser", "win.copy-url" => "Copy Article URL")
    ]
  end

  # Return the text of the menu item that stars or unstars an article.
  #
  # @param article [Article] The article that the menu item stars or unstars.
  # @return [String] The text.
  def star_text(article)
    if @state.starred?(article)
      "Mark as Unstarred"
    else
      "Mark as Starred"
    end
  end
end
