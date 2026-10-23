# frozen_string_literal: true

class ImageView
  include Ui

  attr_reader :widget

  # Start downloading the image.
  #
  # @param url [String] Where to download the image from.
  # @param display_width [Integer] The width the article asks for, or zero.
  # @param downloader [ImageDownloader] Where to queue the download.
  # @param on_ready [#call] Called with this view once the image can be drawn.
  # @param still_open [#call] Called to find out whether the article is still showing.
  def initialize(url, display_width, downloader:, on_ready:, still_open:)
    @display_width = display_width
    @downloader    = downloader
    @on_ready      = on_ready
    @still_open    = still_open
    @size          = nil
    @widget        = build(Gtk::DrawingArea, css: "body-image", halign: :start, visible: false)
    download(url)
  end

  # Size the image to the width the article asks for, shrunk to fit the column.
  #
  # @param available [Integer] The width of the text column, in pixels.
  # @return [void]
  def fit(available)
    if @surface
      width = [natural_width, available].min
      size  = [width, (@height * width.to_f / @width).round]

      resize(size) if size != @size
    end
  end

  # Free the pixels of the image.
  #
  # The draw function would otherwise keep them alive for as long as GTK holds
  # on to the widget, which can be long after the article has been closed.
  #
  # @return [void]
  def release
    @widget.set_draw_func { nil }

    @surface = nil
  end

  private

  # Have GTK decode the image, then keep a copy scaled to what the article
  # can show.
  #
  # Images are often far larger than they are shown, and every pixel costs four
  # bytes, so only the scaled copy is kept.
  #
  # @param data [String] The downloaded bytes.
  # @return [void]
  def decode(data)
    @surface = shrink(Gdk::Texture.new(GLib::Bytes.new(data)))
    @width   = @surface.width
    @height  = @surface.height
  end

  # Queue the download of the image, and show it once it has arrived, unless
  # another article has been opened since.
  #
  # @param url [String] Where to download the image from.
  # @return [void]
  def download(url)
    @downloader.fetch(url, still_wanted: @still_open) do |data|
      GLib::Idle.add do
        show(data) if show?(data)
        false # one-shot
      end
    end
  end

  # Return the width to show the image at when there is room.
  #
  # @return [Integer] The width the article asks for, or the width of the image itself.
  def natural_width
    if @display_width.positive?
      @display_width
    else
      @width
    end
  end

  # Draw the image scaled to fill the widget.
  #
  # @param cairo [Cairo::Context] The context to draw on.
  # @param width [Integer] The width of the widget.
  # @param height [Integer] The height of the widget.
  # @return [void]
  def paint(cairo, width, height)
    cairo.scale(width.to_f / @width, height.to_f / @height)
    cairo.set_source(@surface, 0, 0)
    cairo.source.filter = Cairo::Filter::GOOD
    cairo.paint
  end

  # Return the most pixels wide the image is worth keeping.
  #
  # The limit is a multiple of the widest the image will be shown, so that it
  # stays sharp on a high-resolution display.
  #
  # @return [Integer] The width in pixels.
  def pixel_limit
    shown = READER_MAX_WIDTH - COLUMN_PADDING
    shown = [@display_width, shown].min if @display_width.positive?

    IMAGE_OVERSAMPLE * shown
  end

  # Set the size that the widget asks for.
  #
  # @param size [Array<Integer>] The width and the height.
  # @return [void]
  def resize(size)
    @size = size
    @widget.content_width, @widget.content_height = size
  end

  # Decode the image and reveal it.
  #
  # @param data [String] The downloaded bytes.
  # @return [void]
  def show(data)
    decode(data)
    @widget.set_draw_func { |_area, cairo, width, height| paint(cairo, width, height) }
    @widget.visible = true
    @on_ready.call(self)
  rescue StandardError => error
    warn "reader: cannot decode image: #{error.message}"
  end

  # Return whether a download is worth showing.
  #
  # @param data [String, nil] The downloaded bytes.
  # @return [Boolean] Whether there are bytes and the article is still open.
  def show?(data)
    !data.nil? && @still_open.call
  end

  # Scale a decoded image down to the most pixels the article can show.
  #
  # @param texture [Gdk::Texture] The decoded image.
  # @return [Cairo::ImageSurface] The image, at most as wide as is worth keeping.
  def shrink(texture)
    Scaling.surface(texture, [texture.width, pixel_limit].min)
  end
end
