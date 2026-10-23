# frozen_string_literal: true

class FeedAvatar
  include Ui

  ICON_PIXELS = 64 # The most pixels wide an icon is kept at, which is sharp at twice the largest size shown.

  @textures = {}

  class << self
    # Forget the decoded icon of one feed, so that an icon fetched since is shown.
    #
    # @param feed [Feed] The feed whose icon to forget.
    # @return [void]
    def evict(feed)
      @textures.delete(feed.url)
    end

    # Return the decoded icon of a feed, decoding it the first time.
    #
    # The sidebar and every row of the article list show the icon, so each one
    # is decoded once and shared.
    #
    # @param feed [Feed] The feed whose icon to return.
    # @return [Gdk::Texture] The icon.
    # @return [nil] When the feed has no icon, or it cannot be decoded.
    def texture(feed)
      unless @textures.key?(feed.url)
        @textures[feed.url] = decode(feed.icon.read)
      end

      @textures[feed.url]
    end

    private

    # Decode an icon and scale it down to the size it is kept at.
    #
    # Touch icons are often 180 pixels wide, and scaling them down again on
    # every draw costs more than doing it once.
    #
    # @param data [String, nil] The bytes of the image.
    # @return [Gdk::Texture] The icon.
    # @return [nil] When there is no image, or it cannot be decoded.
    def decode(data)
      if data
        shrink(Gdk::Texture.new(GLib::Bytes.new(data)))
      end
    rescue StandardError => error
      warn "reader: cannot decode icon: #{error.message}"
      nil
    end

    # Return a copy of a texture that fits the size icons are kept at.
    #
    # @param texture [Gdk::Texture] The decoded icon.
    # @return [Gdk::Texture] The texture, or a smaller copy of it.
    def shrink(texture)
      if texture.width <= ICON_PIXELS
        texture
      else
        Scaling.texture(Scaling.surface(texture, ICON_PIXELS))
      end
    end
  end

  attr_reader :widget

  # Build an empty avatar.
  #
  # @param size [Integer] The width and height, in pixels.
  # @param large [Boolean] Whether the monogram uses the larger letter of the reading pane.
  def initialize(size, large: false)
    @image  = build(Gtk::Image, css: "avatar", pixel_size: size, visible: false)
    @letter = build(Gtk::DrawingArea, content_height: size, content_width: size, css: ["monogram", *("large" if large)],
                                      visible: false)
    @text   = ""
    @tint   = nil
    @widget = box(:horizontal, 0, [@image, @letter], valign: :start)
    @letter.set_draw_func { |area, cairo, width, height| draw_letter(area, cairo, width, height) }
  end

  # Show the icon of a feed, or a lettered tile when it has none.
  #
  # @param feed [Feed] The feed whose icon to show.
  # @return [void]
  def show(feed)
    texture = self.class.texture(feed)

    @image.paintable = texture
    @image.visible   = !texture.nil?
    @letter.visible  = texture.nil?
    if texture.nil?
      show_monogram(feed.name)
    end
  end

  private

  # Draw the letter in the middle of the tile, whose color comes from the
  # stylesheet.
  #
  # The letter is centered on its own ink. A label centers the whole line, with
  # room for descenders, which leaves a capital letter sitting high.
  #
  # @param area [Gtk::DrawingArea] The tile.
  # @param cairo [Cairo::Context] The context to draw on.
  # @param width [Integer] The width of the tile.
  # @param height [Integer] The height of the tile.
  # @return [void]
  def draw_letter(area, cairo, width, height)
    layout = area.create_pango_layout(@text)
    color  = area.color

    cairo.set_source_rgba(color.red, color.green, color.blue, color.alpha)
    cairo.move_to(*ink_origin(layout, width, height))
    cairo.show_pango_layout(layout)
  end

  # Return where to draw a layout so that its ink is centered in a tile.
  #
  # @param layout [Pango::Layout] The laid-out letter.
  # @param width [Integer] The width of the tile.
  # @param height [Integer] The height of the tile.
  # @return [Array<Float>] The left and the top of the layout.
  def ink_origin(layout, width, height)
    ink, _logical = layout.pixel_extents

    [((width - ink.width) / 2.0) - ink.x, ((height - ink.height) / 2.0) - ink.y]
  end

  # Show the lettered tile for a feed.
  #
  # @param name [String] The name of the feed.
  # @return [void]
  def show_monogram(name)
    if @tint
      @letter.remove_css_class(@tint)
    end

    @tint = Monogram.tint(name)
    @letter.add_css_class(@tint)
    @text = Monogram.letter(name)
    @letter.queue_draw
  end
end
