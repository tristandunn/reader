# frozen_string_literal: true

class FeedsHeading
  include Ui

  attr_reader :widget

  # Build the Feeds heading, collapsed or not as the state left it.
  #
  # @param state [ReadState] Where whether the feeds are collapsed is recorded.
  # @param on_toggle [#call] Called after the heading is clicked and the feeds should be shown or hidden.
  def initialize(state, on_toggle:)
    @state     = state
    @on_toggle = on_toggle
    @arrow     = build(Gtk::Image, css: "heading-arrow", icon_name: arrow_icon, pixel_size: 12)
    @widget    = build(Gtk::ListBoxRow, child: box(:horizontal, 0, [label("Feeds", "heading", hexpand: true), @arrow]),
                                        css: "heading-row", focusable: false, selectable: false)

    add_click
  end

  # Return whether the feeds below the heading are hidden.
  #
  # @return [Boolean] Whether the Feeds section is collapsed.
  def collapsed?
    @state.feeds_collapsed?
  end

  private

  # Collapse or expand the feeds on a click.
  #
  # @return [void]
  def add_click
    click = Gtk::GestureClick.new

    click.signal_connect("pressed") { toggle }
    @widget.add_controller(click)
  end

  # Return the icon that points at the state of the heading.
  #
  # @return [String] The name of the icon.
  def arrow_icon
    if collapsed?
      "pan-end-symbolic"
    else
      "pan-down-symbolic"
    end
  end

  # Collapse the feeds when they are shown, and expand them otherwise.
  #
  # @return [void]
  def toggle
    @state.feeds_collapsed = !collapsed?
    @state.save
    @arrow.icon_name = arrow_icon

    @on_toggle.call
  end
end
