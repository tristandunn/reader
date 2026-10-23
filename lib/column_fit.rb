# frozen_string_literal: true

class ColumnFit
  # Keep a column left-aligned and filling its pane, but capped at a
  # comfortable line length, with its images sized to fit.
  #
  # The column is fitted again whenever the width of the pane changes, which is
  # all that can change it. The width changes while GTK is laying out the
  # window, and GTK ignores a new margin set then until something else asks for
  # a layout, such as a scroll. So the fitting waits until the layout is done,
  # or a window moved to a smaller size in one step keeps its wider text.
  #
  # @param scroll [Gtk::ScrolledWindow] The pane that scrolls the column.
  # @param column [Gtk::Widget] The column to fit.
  def initialize(scroll, column)
    @scroll  = scroll
    @column  = column
    @images  = []
    @pending = nil
    @scroll.hadjustment.signal_connect("notify::page-size") { schedule }
  end

  # Start sizing an image that has finished loading.
  #
  # @param image [ImageView] The image to size.
  # @return [void]
  def add(image)
    @images << image
    fit_images
  end

  # Free the pixels of every image, and stop sizing them.
  #
  # @return [Boolean] Whether there were images to free.
  def release
    freed = !@images.empty?

    @images.each(&:release)
    @images.clear
    freed
  end

  private

  # Fit the column and its images to the width of the pane.
  #
  # @return [void]
  def fit
    @column.margin_end = Column.margin_end(viewport_width)
    fit_images
  end

  # Size every image to fit the text column.
  #
  # @return [void]
  def fit_images
    available = Column.text_width(viewport_width)

    if available.positive?
      @images.each { |image| image.fit(available) }
    end
  end

  # Fit the column once the layout in progress is done, at most once per
  # layout.
  #
  # @return [void]
  def schedule
    if @pending.nil?
      @pending = GLib::Idle.add do
        @pending = nil
        fit
        false # one-shot
      end
    end
  end

  # Return the width of the pane.
  #
  # @return [Integer] The width, in pixels, which is zero before the first layout.
  def viewport_width
    @scroll.hadjustment.page_size.to_i
  end
end
