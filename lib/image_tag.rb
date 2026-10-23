# frozen_string_literal: true

module ImageTag
  module_function

  # Return the source of an image.
  #
  # Lazy-loading pages keep it in `data-src`.
  #
  # @param node [Nokogiri::XML::Element] The `img` element.
  # @return [String] The source.
  # @return [nil] When the image has none.
  def source(node)
    node["src"] || node["data-src"]
  end

  # Return whether an image is worth showing.
  #
  # @param node [Nokogiri::XML::Element] The `img` element.
  # @return [Boolean] Whether the image has a source and is not a tracking pixel.
  def usable?(node)
    !source(node).to_s.empty? && !tracking_pixel?(node)
  end

  # Return whether an image declares itself a pixel or two wide or tall, as
  # trackers do.
  #
  # @param node [Nokogiri::XML::Element] The `img` element.
  # @return [Boolean] Whether the image is a tracking pixel.
  def tracking_pixel?(node)
    [node["width"], node["height"]].any? { |size| size.to_i.between?(1, 2) }
  end

  # Build the block for an image.
  #
  # @param node [Nokogiri::XML::Element] The `img` element.
  # @return [Array] The source, followed by the width the article asks for, or zero.
  def block(node)
    [source(node), node["width"].to_i]
  end
end
