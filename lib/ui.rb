# frozen_string_literal: true

module Ui
  private

  # Create a box that holds the children.
  #
  # @param orientation [Symbol] Either `:horizontal` or `:vertical`.
  # @param spacing [Integer] The pixels between children.
  # @param children [Array<Gtk::Widget>] The widgets to append.
  # @param options [Hash] The CSS classes and the properties, as for {#build}.
  # @option options [String, Array<String>] :css The CSS classes to add.
  # @return [Gtk::Box] The box.
  def box(orientation, spacing, children, **options)
    build(Gtk::Box, orientation, spacing, children: children, **options)
  end

  # Create a widget, set its properties, add CSS classes and append children.
  #
  # @param widget_class [Class] The GTK class to instantiate.
  # @param args [Array<Object>] The constructor arguments.
  # @param children [Array<Gtk::Widget>] The widgets to append, for containers.
  # @param css [String, Array<String>] The CSS classes to add.
  # @param properties [Hash{Symbol => Object}] The values to assign with the writers of the widget.
  # @option properties [Object] :property The value for the writer of the same name, such as `halign=`.
  # @return [Gtk::Widget] The widget.
  def build(widget_class, *args, children: [], css: [], **properties)
    widget = widget_class.new(*args)

    Array(css).each { |name| widget.add_css_class(name) }
    properties.each { |name, value| widget.public_send("#{name}=", value) }
    children.each { |child| widget.append(child) }
    widget
  end

  # Remove every child of a box.
  #
  # @param box [Gtk::Box] The box to empty.
  # @return [void]
  def clear(box)
    while (child = box.first_child)
      box.remove(child)
    end
  end

  # Create a faint icon above a line of text, for a pane with nothing to show.
  #
  # @param icon [String] The name of the icon.
  # @param text [Gtk::Label] The label that says why the pane is empty.
  # @return [Gtk::Box] The empty state, centered in the space it is given.
  def empty_state(icon, text)
    image = build(Gtk::Image, css: "empty-icon", icon_name: icon, pixel_size: 48)

    box(:vertical, 12, [image, text], halign: :center, valign: :center, vexpand: true)
  end

  # Create a label that is left-aligned unless a property says otherwise.
  #
  # @param text [String] The text to show.
  # @param classes [Array<String>] The CSS classes to add.
  # @param properties [Hash{Symbol => Object}] The values to assign with the writers of the label.
  # @option properties [Object] :property The value for the writer of the same name, such as `ellipsize=`.
  # @return [Gtk::Label] The label.
  def label(text, *classes, **properties)
    build(Gtk::Label, text, css: classes, xalign: 0.0, **properties)
  end

  # Build a horizontal pane whose start child keeps its width when the
  # window resizes.
  #
  # @param start_child [Gtk::Widget] The widget on the left.
  # @param end_child [Gtk::Widget] The widget on the right.
  # @param position [Integer] The width of the start child, in pixels.
  # @return [Gtk::Paned] The pane.
  def pane(start_child, end_child, position)
    build(Gtk::Paned, :horizontal, end_child: end_child, position: position, resize_start_child: false,
                                   shrink_start_child: false, start_child: start_child)
  end

  # Build the header of one pane.
  #
  # Each pane has its own header rather than the window sharing one, so the
  # buttons sit above the column they act on and the sidebar color runs to the
  # top of the window.
  #
  # @param controls [Boolean] Whether the header holds the button that closes the window.
  # @param finish [Array<Gtk::Widget>] The widgets at the end of the header, from the outside in.
  # @param start [Array<Gtk::Widget>] The widgets at the start of the header.
  # @param title [Gtk::Widget, nil] The widget in the middle, or nil for none.
  # @return [Gtk::HeaderBar] The header.
  def pane_header(controls: false, finish: [], start: [], title: nil)
    header = build(Gtk::HeaderBar, css: "pane-header", decoration_layout: ":close", show_title_buttons: controls,
                                   title_widget: title || box(:horizontal, 0, []))

    start.each { |widget| header.pack_start(widget) }
    finish.each { |widget| header.pack_end(widget) }
    header
  end

  # Add or remove a CSS class.
  #
  # @param widget [Gtk::Widget] The widget to restyle.
  # @param name [String] The CSS class.
  # @param enabled [Boolean] Whether the widget should have the class.
  # @return [void]
  def toggle_class(widget, name, enabled)
    if enabled
      widget.add_css_class(name)
    else
      widget.remove_css_class(name)
    end
  end

  # Create a flat icon button for a pane header.
  #
  # @param icon [String] The name of the icon.
  # @param tooltip [String] The text of the tooltip.
  # @yield Called when the button is clicked.
  # @return [Gtk::Button] The button.
  def toolbar_button(icon, tooltip, &)
    button = build(Gtk::Button, icon_name: icon, tooltip_text: tooltip, css: "toolbar-button")

    button.signal_connect("clicked", &)
    button
  end
end
