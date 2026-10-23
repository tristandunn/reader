# frozen_string_literal: true

module TableRows
  BLOCKS = %w(table p div ul ol li h1 h2 h3 h4 h5 h6 img blockquote pre figure).map do |tag|
    ".//#{tag}"
  end.join(" | ").freeze

  module_function

  # Return whether a table holds data, which is worth showing as a grid.
  #
  # Email newsletters lay out their whole content in tables, with paragraphs,
  # images and further tables in the cells, or with long runs of text in a
  # cell. Those flow as ordinary content instead, because a grid would wrap each
  # cell into a very tall, narrow column. So do tables with nothing to show.
  #
  # @param table [Nokogiri::XML::Element] The `table` element.
  # @return [Boolean] Whether no cell holds block content, and the text of the cells is short.
  def data?(table)
    cells = table.xpath(".//td | .//th")

    cells.none? { |cell| cell.at_xpath(BLOCKS) } && short_text?(cells.map { |cell| Text.plain(cell.inner_html) })
  end

  # Read the rows of a table, leaving out the empty ones.
  #
  # @param table [Nokogiri::XML::Element] The `table` element.
  # @return [Array<Array<String>>] The markup of each cell, by row.
  def parse(table)
    rows = table.xpath(".//tr").map { |row| row.xpath("./th | ./td").map { |cell| markup(cell) } }

    rows.reject { |row| row.all?(&:empty?) }
  end

  # Return the markup of one table cell, which is bold for a header cell.
  #
  # @param cell [Nokogiri::XML::Element] The `th` or `td` element.
  # @return [String] The markup.
  def markup(cell)
    text = ArticleBlocks.parse(cell.inner_html).map(&:last).join("\n")

    if bold?(cell, text)
      "<b>#{text}</b>"
    else
      text
    end
  end

  # Return whether the markup of a cell should be bold.
  #
  # @param cell [Nokogiri::XML::Element] The `th` or `td` element.
  # @param text [String] The markup of the cell.
  # @return [Boolean] Whether the cell is a header cell with something in it.
  def bold?(cell, text)
    cell.name == "th" && !text.empty?
  end

  # Return whether the text of the cells of a table is worth a grid.
  #
  # @param texts [Array<String>] The plain text of each cell.
  # @return [Boolean] Whether some cell has text and none is longer than a grid cell takes.
  def short_text?(texts)
    texts.any? { |text| !text.empty? } && texts.all? { |text| text.length <= TABLE_CELL_MAX_CHARS }
  end
end
