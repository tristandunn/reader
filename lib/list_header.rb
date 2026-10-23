# frozen_string_literal: true

class ListHeader
  include Ui

  attr_reader :widget

  # Build the header above the article list.
  #
  # @param on_mark_all_read [#call] Called when the button that marks every article as read is clicked.
  # @param on_toggle_read [#call] Called when the button that hides the read articles is toggled.
  def initialize(on_mark_all_read:, on_toggle_read:)
    @title     = label("", "pane-title", ellipsize: :end)
    @subtitle  = label("", "pane-subtitle")
    @mark_read = toolbar_button("object-select-symbolic", "Mark All as Read") { on_mark_all_read.call }
    @hide_read = build_hide_read(on_toggle_read)
    @widget    = pane_header(start:  [box(:vertical, 0, [@title, @subtitle], valign: :center)],
                             finish: [@hide_read, @mark_read])
  end

  # Return whether the read articles are hidden.
  #
  # @return [Boolean] Whether the button that hides the read articles is on.
  def hide_read?
    @hide_read.active?
  end

  # Show the name of the list and how many of its articles are unread.
  #
  # @param title [String] The name of the list.
  # @param unread [Integer] How many of its articles are unread.
  # @return [void]
  def update(title, unread)
    @title.text          = title
    @subtitle.text       = subtitle(unread)
    @mark_read.sensitive = unread.positive?
  end

  private

  # Build the button that hides or shows the read articles.
  #
  # @param on_toggle_read [#call] Called when the button is toggled.
  # @return [Gtk::ToggleButton] The button.
  def build_hide_read(on_toggle_read)
    button = build(Gtk::ToggleButton, icon_name: "view-reveal-symbolic", tooltip_text: "Hide Read Articles",
                                      css: "toolbar-button")

    button.signal_connect("toggled") { on_toggle_read.call }
    button
  end

  # Return the line under the name of the list.
  #
  # @param unread [Integer] How many articles are unread.
  # @return [String] The line.
  def subtitle(unread)
    "#{unread} unread"
  end
end
