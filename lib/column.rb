# frozen_string_literal: true

module Column
  module_function

  # Return the margin that keeps the column to a comfortable line length.
  #
  # GTK has no maximum width, so the width beyond the widest column is taken up
  # by a margin on the right.
  #
  # @param viewport [Integer] The width of the reading pane, in pixels.
  # @return [Integer] The margin, which is zero in a narrow pane.
  def margin_end(viewport)
    [viewport - READER_MAX_WIDTH, 0].max
  end

  # Return the width available to the text of the column.
  #
  # @param viewport [Integer] The width of the reading pane, in pixels.
  # @return [Integer] The width, after the padding of the column.
  def text_width(viewport)
    [viewport, READER_MAX_WIDTH].min - COLUMN_PADDING
  end
end
