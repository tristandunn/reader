# frozen_string_literal: true

module Scaling
  module_function

  # Draw one image onto another, scaled to fill it.
  #
  # @param source [Cairo::ImageSurface] The image to draw.
  # @param target [Cairo::ImageSurface] The image to draw onto.
  # @return [Cairo::ImageSurface] The target.
  def draw(source, target)
    context = Cairo::Context.new(target)

    context.scale(target.width.fdiv(source.width), target.height.fdiv(source.height))
    context.set_source(source, 0, 0)
    context.source.filter = Cairo::Filter::GOOD
    context.paint
    target
  end

  # Copy the pixels of a decoded image out of GTK.
  #
  # The pixels are premultiplied BGRA, which is what Cairo calls ARGB32.
  #
  # @param texture [Gdk::Texture] The decoded image.
  # @return [String] The pixels, four bytes each, row by row.
  def pixels(texture)
    pixels = "\0".b * (texture.height * texture.width * 4)

    texture.download(pixels, texture.width * 4)
    pixels
  end

  # Return a copy of a decoded image, scaled to a width.
  #
  # A Cairo surface does not keep its pixels alive, so they are held here
  # until the copy has been drawn.
  #
  # @param texture [Gdk::Texture] The decoded image.
  # @param width [Integer] The width of the copy, in pixels, where the height keeps the proportions.
  # @return [Cairo::ImageSurface] The copy.
  def surface(texture, width)
    pixels = pixels(texture)
    source = Cairo::ImageSurface.new(pixels, Cairo::FORMAT_ARGB32, texture.width, texture.height, texture.width * 4)
    height = [(texture.height * width.fdiv(texture.width)).round, 1].max

    draw(source, Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, width, height))
  end

  # Return a texture that holds the pixels of a surface.
  #
  # @param surface [Cairo::ImageSurface] The drawn image to hand to GTK.
  # @return [Gdk::Texture] The texture.
  def texture(surface)
    surface.flush

    Gdk::MemoryTexture.new(surface.width, surface.height, Gdk::MemoryFormat::B8G8R8A8_PREMULTIPLIED,
                           GLib::Bytes.new(surface.data), surface.stride)
  end
end
