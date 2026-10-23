# frozen_string_literal: true

class BlockWidgets
  include Ui

  # Create the builder for the blocks of one article.
  #
  # @param article [Article] The article the blocks belong to.
  # @param downloader [ImageDownloader] Where images are downloaded.
  # @param on_image [#call] Called with each image view once it can be drawn.
  # @param still_open [#call] Called to find out whether the article is still showing.
  def initialize(article, downloader:, on_image:, still_open:)
    @article    = article
    @downloader = downloader
    @on_image   = on_image
    @still_open = still_open
  end

  # Build the widget for a block.
  #
  # @param kind [Symbol] The kind of the block, as produced by {ArticleBlocks}.
  # @param markup [String, Array] The markup of the block, or its parts for lists, quotes, tables and images.
  # @return [Gtk::Widget] The widget.
  def widget(kind, markup)
    case kind
    when :list then list(markup)
    when :quote then quote(markup)
    when :table then table(markup)
    when :image then image(*markup)
    when :pre then body_label(markup, "body-pre")
    when :h then body_label(markup, "body-h")
    else body_label(markup, "body-p")
    end
  end

  private

  # Resolve the source of an image against the link of the article.
  #
  # @param source [String] The source of the image.
  # @return [String] The URL.
  # @return [nil] When the URL is not http or https.
  def absolute_url(source)
    url = URI.join(@article.link, source.strip).to_s

    if url.match?(%r{\Ahttps?://}i)
      url
    end
  rescue URI::Error
    nil
  end

  # Build a wrapping, selectable label for a block of Pango markup.
  #
  # @param markup [String] The Pango markup.
  # @param classes [Array<String>] The CSS classes to add.
  # @param properties [Hash{Symbol => Object}] The values to assign with the writers of the label.
  # @option properties [Object] :property The value for the writer of the same name, such as `max_width_chars=`.
  # @return [Gtk::Label] The label.
  def body_label(markup, *classes, **properties)
    widget = label("", *classes, can_focus: false, max_width_chars: 68, selectable: true, use_markup: true,
                                 wrap: true, wrap_mode: :word_char, **properties)
    widget.markup = markup
    widget
  end

  # Build an image, which fills in once it has downloaded.
  #
  # @param source [String] The source of the image.
  # @param display_width [Integer] The width the article asks for, or zero.
  # @return [Gtk::Widget] The image, or an empty widget when the source cannot be used.
  def image(source, display_width)
    url = absolute_url(source)

    if url
      ImageView.new(url, display_width, downloader: @downloader, on_ready: @on_image, still_open: @still_open).widget
    else
      build(Gtk::Box, :vertical, 0, visible: false)
    end
  end

  # Build a bulleted list.
  #
  # @param items [Array<String>] The markup of each item.
  # @return [Gtk::Box] The list.
  def list(items)
    box(:vertical, 6, items.map { |item| list_item(item) }, margin_start: 4)
  end

  # Build one bulleted item.
  #
  # @param markup [String] The markup of the item.
  # @return [Gtk::Box] The bullet and the text.
  def list_item(markup)
    bullet = label("•", "body-p", "body-bullet", valign: :start)

    box(:horizontal, 10, [bullet, body_label(markup, "body-p")])
  end

  # Build paragraphs with a bar down the left edge.
  #
  # @param paragraphs [Array<String>] The markup of each paragraph.
  # @return [Gtk::Box] The quote.
  def quote(paragraphs)
    box(:vertical, 14, paragraphs.map { |paragraph| body_label(paragraph, "body-p") }, css: "body-quote")
  end

  # Build a grid of cells, with the first row as the header.
  #
  # @param rows [Array<Array<String>>] The markup of each cell, by row.
  # @return [Gtk::Grid] The table.
  def table(rows)
    grid = build(Gtk::Grid, css: "body-table", halign: :start)

    rows.each_with_index { |row, index| table_row(grid, row, index) }
    grid
  end

  # Build one table cell.
  #
  # @param markup [String] The markup of the cell.
  # @param header [Boolean] Whether the cell is in the header row.
  # @return [Gtk::Label] The cell.
  def table_cell(markup, header:)
    cell = body_label(markup, "body-p", "body-cell", max_width_chars: 30)
    cell.add_css_class("body-th") if header
    cell
  end

  # Add one row of cells to a grid.
  #
  # @param grid [Gtk::Grid] The grid to add the cells to.
  # @param row [Array<String>] The markup of each cell.
  # @param index [Integer] The index of the row.
  # @return [void]
  def table_row(grid, row, index)
    row.each_with_index { |cell, column| grid.attach(table_cell(cell, header: index.zero?), column, index, 1, 1) }
  end
end
