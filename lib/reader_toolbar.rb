# frozen_string_literal: true

class ReaderToolbar
  include Ui

  attr_reader :widget

  # Build the header above the reading pane, with the buttons that act on the
  # article being read.
  #
  # @param commands [#call] Called to get the {Commands} that the buttons run, which are created after the toolbar.
  def initialize(commands)
    @read    = toolbar_button("mail-read-symbolic", "Mark as Read") { commands.call.toggle_read }
    @star    = toolbar_button("non-starred-symbolic", "Mark as Starred") { commands.call.toggle_star }
    @next    = toolbar_button("go-down-symbolic", "Next Unread") { commands.call.next_unread }
    @browser = toolbar_button("send-to-symbolic", "Open in Browser") { commands.call.open_in_browser }
    @widget  = pane_header(start: [@read, @star], finish: [@browser, @next], controls: true)
    update(nil, read: false, starred: false)
  end

  # Match the buttons to the article being read.
  #
  # @param article [Article, nil] The article, which disables the buttons that act on one when absent.
  # @param read [Boolean] Whether the article is read.
  # @param starred [Boolean] Whether the article is starred.
  # @return [void]
  def update(article, read:, starred:)
    [@read, @star, @browser].each { |button| button.sensitive = !article.nil? }
    show_read(read)
    show_star(starred)
  end

  private

  # Show whether the read button marks the article as read or as unread.
  #
  # @param read [Boolean] Whether the article is read.
  # @return [void]
  def show_read(read)
    @read.icon_name    = read ? "mail-unread-symbolic" : "mail-read-symbolic"
    @read.tooltip_text = read ? "Mark as Unread" : "Mark as Read"
  end

  # Show whether the star button stars the article or unstars it.
  #
  # @param starred [Boolean] Whether the article is starred.
  # @return [void]
  def show_star(starred)
    @star.icon_name    = starred ? "starred-symbolic" : "non-starred-symbolic"
    @star.tooltip_text = starred ? "Mark as Unstarred" : "Mark as Starred"
    toggle_class(@star, "starred", starred)
  end
end
