# frozen_string_literal: true

class SidebarRow
  include Ui

  attr_reader :entry, :widget

  # Build the row of an entry, with its icon, its title and its unread badge.
  #
  # @param entry [Library::Entry] The entry that the row shows.
  def initialize(entry)
    @entry  = entry
    @avatar = nil
    @count  = label("", "count", xalign: 1.0)
    @widget = build(Gtk::ListBoxRow, child: box(:horizontal, 0, [icon, title, @count]))
  end

  # Set the badge to a count, leaving it blank for zero.
  #
  # @param value [Integer] The number of unread articles.
  # @return [void]
  def count=(value)
    @count.text = value.zero? ? "" : value.to_s
  end

  # Show the icon of the feed again, in case it was fetched since.
  #
  # @return [void]
  def refresh_icon
    @avatar&.show(@entry.key)
  end

  private

  # Build the icon: a colored symbol for a smart feed, and the icon of the feed
  # otherwise.
  #
  # @return [Gtk::Widget] The icon.
  def icon
    if @entry.smart?
      build(Gtk::Image, css: ["sidebar-icon", @entry.key.to_s], icon_name: @entry.icon, pixel_size: 16)
    else
      @avatar = FeedAvatar.new(16)

      @avatar.show(@entry.key)
      @avatar.widget.valign = :center
      @avatar.widget
    end
  end

  # Build the title, which takes the room the badge leaves.
  #
  # @return [Gtk::Label] The label.
  def title
    label(@entry.title, "feed-name", ellipsize: :end, hexpand: true)
  end
end
