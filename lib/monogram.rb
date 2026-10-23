# frozen_string_literal: true

module Monogram
  TINTS = 8 # The tint classes in the stylesheet, from `tint-0`.

  module_function

  # Return the letter that stands in for the icon of a feed that has none.
  #
  # @param name [String] The name of the feed.
  # @return [String] The first letter or digit, capitalized, or a bullet when there is none.
  def letter(name)
    first = name[/[[:alnum:]]/]

    if first
      first.upcase
    else
      "•"
    end
  end

  # Return the color class of a monogram.
  #
  # The color comes from the name, so a feed keeps its color from one run to
  # the next, and neighbors in the sidebar tend to differ.
  #
  # @param name [String] The name of the feed.
  # @return [String] The CSS class, from `tint-0` up.
  def tint(name)
    "tint-#{name.sum % TINTS}"
  end
end
