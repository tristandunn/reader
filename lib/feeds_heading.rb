# frozen_string_literal: true

class FeedsHeading
  include Ui

  attr_reader :widget

  # Build the Feeds heading, which starts out expanded.
  #
  # @param on_toggle [#call] Called after the heading is clicked and the feeds should be shown or hidden.
  def initialize(on_toggle:)
    @on_toggle = on_toggle
    @collapsed = false
    @arrow     = build(Gtk::Image, css: "heading-arrow", icon_name: "pan-down-symbolic", pixel_size: 12)
    @widget    = build(Gtk::ListBoxRow, child: box(:horizontal, 0, [label("Feeds", "heading", hexpand: true), @arrow]),
                                        css: "heading-row", focusable: false, selectable: false)

    add_click
  end

  # Return whether the feeds below the heading are hidden.
  #
  # @return [Boolean] Whether the Feeds section is collapsed.
  def collapsed?
    @collapsed
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

  # Collapse the feeds when they are shown, and expand them otherwise.
  #
  # @return [void]
  def toggle
    @collapsed       = !@collapsed
    @arrow.icon_name = @collapsed ? "pan-end-symbolic" : "pan-down-symbolic"

    @on_toggle.call
  end
end
