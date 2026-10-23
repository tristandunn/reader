# frozen_string_literal: true

class Sidebar
  include Ui

  attr_reader :widget

  # Build the sidebar.
  #
  # @param on_refresh [#call] Called when the refresh button is clicked.
  # @param on_select [#call] Called with the entry of a row that gets selected.
  def initialize(on_refresh:, on_select:)
    @on_select  = on_select
    @rows       = []
    @rebuilding = false
    @heading    = FeedsHeading.new(on_toggle: method(:apply_collapsed))
    @list       = build_list
    @status     = RefreshStatus.new
    @widget     = build_widget(on_refresh)
  end

  # Set each badge to its count, leaving it blank for zero.
  #
  # @param values [Array<Integer>] The count of each entry, in order.
  # @return [void]
  def counts=(values)
    @rows.zip(values) { |row, value| row.count = value }
  end

  # Move the keyboard focus to the selected row.
  #
  # @return [void]
  def focus
    @list.selected_row&.grab_focus
  end

  # Hide the section that shows the progress of a refresh.
  #
  # @return [void]
  def hide_progress
    @status.hide
  end

  # Replace the rows without announcing a selection.
  #
  # @param entries [Array<Library::Entry>] The entries to list.
  # @param selected_key [Symbol, Feed] The key of the entry to keep selected.
  # @return [void]
  def rebuild(entries, selected_key)
    @rebuilding = true
    clear(@list)
    @rows = entries.map { |entry| SidebarRow.new(entry) }
    append_rows
    apply_collapsed
    @list.select_row(row_for(selected_key) || @rows.first&.widget)
  ensure
    @rebuilding = false
  end

  # Show the icon of a feed again, once it may have been fetched.
  #
  # The decoded icon is dropped first, since it was decoded before the fetch.
  #
  # @param feed [Feed] The feed whose icon to show.
  # @return [void]
  def refresh_icon(feed)
    FeedAvatar.evict(feed)
    @rows.find { |row| row.entry.key.equal?(feed) }&.refresh_icon
  end

  # Select the entry with a key, which announces it.
  #
  # @param key [Symbol, Feed] The key of the entry.
  # @return [void]
  def select(key)
    widget = row_for(key)

    if widget
      @list.select_row(widget)
    end
  end

  # Select the entry some rows from the selected one, which announces it.
  #
  # @param delta [Integer] How many entries to move, where a negative number moves up.
  # @return [void]
  def select_relative(delta)
    target = visible_target(index_of(@list.selected_row).to_i, delta)

    if target
      @list.select_row(@rows[target].widget)
      @rows[target].widget.grab_focus
    end
  end

  # Show how far a refresh has got, in a section at the bottom.
  #
  # @param done [Integer] How many feeds have been loaded.
  # @param total [Integer] How many feeds there are.
  # @return [void]
  def show_progress(done, total)
    @status.update(done, total)
  end

  private

  # Return whether selecting a row should be announced.
  #
  # @param index [Integer, nil] The position of the entry of the row.
  # @return [Boolean] Whether the entry is known and the rows are not being rebuilt.
  def announce?(index)
    !index.nil? && !@rebuilding
  end

  # Append the rows, with the Feeds heading above the first feed.
  #
  # @return [void]
  def append_rows
    first_feed = @rows.find { |row| !row.entry.smart? }

    @rows.each do |row|
      if row.equal?(first_feed)
        @list.append(@heading.widget)
      end

      @list.append(row.widget)
    end
  end

  # Show or hide the feed rows to match whether the Feeds section is collapsed.
  #
  # @return [void]
  def apply_collapsed
    @rows.each do |row|
      unless row.entry.smart?
        row.widget.visible = !@heading.collapsed?
      end
    end
  end

  # Build the list, announcing the entry of whichever row gets selected.
  #
  # @return [Gtk::ListBox] The list.
  def build_list
    list = build(Gtk::ListBox, css: "sidebar", selection_mode: :single)

    list.signal_connect("row-selected") { |_box, row| select_row(row) }
    list
  end

  # Build the column: the header, the list, and the refresh status below it.
  #
  # @param on_refresh [#call] Called when the refresh button is clicked.
  # @return [Gtk::Box] The column.
  def build_widget(on_refresh)
    refresh = toolbar_button("view-refresh-symbolic", "Refresh") { on_refresh.call }
    scroll  = build(Gtk::ScrolledWindow, child: @list, hscrollbar_policy: :never, vexpand: true)

    box(:vertical, 0, [pane_header(finish: [refresh]), scroll, @status.widget], css:           "sidebar-column",
                                                                                width_request: 200)
  end

  # Return the position of the row of a widget among the entries.
  #
  # @param widget [Gtk::ListBoxRow, nil] The widget of the row.
  # @return [Integer] The position, from zero.
  # @return [nil] When the widget is not the row of an entry.
  def index_of(widget)
    @rows.index { |row| row.widget == widget }
  end

  # Return the widget of the row of the entry with a key.
  #
  # @param key [Symbol, Feed] The key of the entry.
  # @return [Gtk::ListBoxRow] The widget.
  # @return [nil] When no entry has the key.
  def row_for(key)
    @rows.find { |row| row.entry.key == key }&.widget
  end

  # Announce the entry of a selected row, unless the rows are being rebuilt.
  #
  # @param widget [Gtk::ListBoxRow, nil] The selected row.
  # @return [void]
  def select_row(widget)
    index = index_of(widget)

    if announce?(index)
      @on_select.call(@rows[index].entry)
    end
  end

  # Return the position of the nearest visible entry in a direction.
  #
  # @param from [Integer] The position to start from.
  # @param delta [Integer] The direction to look in, where a negative number moves up.
  # @return [Integer] The position.
  # @return [nil] When no visible entry lies in that direction.
  def visible_target(from, delta)
    positions = delta.negative? ? (0...from).to_a.reverse : ((from + 1)...@rows.size).to_a
    shown     = positions.select { |position| @rows[position].widget.visible? }

    shown[delta.abs - 1]
  end
end
