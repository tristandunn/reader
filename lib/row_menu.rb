# frozen_string_literal: true

class RowMenu
  # Create the right-click menu of the article list.
  #
  # @param menu [#call] Called with an article to get its menu.
  def initialize(menu:)
    @menu    = menu
    @popover = nil
  end

  # Remove the open menu, if there is one.
  #
  # @return [void]
  def close
    @popover&.unparent
    @popover = nil
  end

  # Pop up the menu of an article.
  #
  # The menu is parented to the row, not the list, because a popover parented to
  # the list is capped at a fixed height and scrolls instead of showing in full.
  # It is a fresh one per click, since swapping the model of a live one leaves
  # its scroller mis-sized.
  #
  # @param article [Article] The article the menu is for.
  # @param row [Gtk::Widget] The row of the article.
  # @param left [Float] Where to point, in row coordinates.
  # @param top [Float] Where to point, in row coordinates.
  # @return [void]
  def popup(article, row, left, top)
    close
    @popover = Gtk::PopoverMenu.new(@menu.call(article))
    @popover.has_arrow = false
    @popover.halign = :start
    @popover.set_parent(row)
    @popover.pointing_to = Gdk::Rectangle.new(left, top, 1, 1)
    @popover.popup
  end
end
