# frozen_string_literal: true

class ReaderPane
  include Ui

  attr_reader :article, :widget

  # Build the pane, showing the empty state.
  #
  # @param downloader [ImageDownloader] Where the images of articles are downloaded.
  def initialize(downloader:)
    @downloader = downloader
    @article    = nil
    @header     = ArticleHeader.new
    @trimmer    = TrimScheduler.new
    @column     = build_column
    @scroll     = build(Gtk::ScrolledWindow, child: @column, css: "reader", hexpand: true)
    @widget     = build_stack
    @fit        = ColumnFit.new(@scroll, @column)
  end

  # Return whether there is more of the open article below what is in view.
  #
  # @return [Boolean] Whether an article is open and is not scrolled to its end.
  def more_below?
    !@article.nil? && @scroll.vadjustment.value < bottom - 1
  end

  # Swap in the refreshed copy of the article being shown.
  #
  # The content is not drawn again, so the reading position and the images stay
  # as they are.
  #
  # @param article [Article, nil] The refreshed copy, or nil when it is gone.
  # @return [void]
  def refresh(article)
    if article
      @article = article
    end
  end

  # Scroll down by most of a page.
  #
  # A little of the previous page stays in view, so the place is not lost.
  #
  # @return [void]
  def scroll_page
    adjustment = @scroll.vadjustment

    adjustment.value = [adjustment.value + (adjustment.page_size * 0.85), bottom].min
  end

  # Show an article, or the empty state.
  #
  # @param article [Article, nil] The article to show.
  # @return [void]
  def show(article)
    @article = article

    if article
      display(article)
    else
      @widget.visible_child_name = "empty"
    end
  end

  private

  # Start sizing an image that has finished loading.
  #
  # @param image [ImageView] The image to size.
  # @return [void]
  def add_image(image)
    @fit.add(image)
    @trimmer.schedule
  end

  # Return the blocks to show for an article.
  #
  # The snippet is used when the content has nothing to show.
  #
  # @param article [Article] The article whose blocks to build.
  # @return [Array<Array>] The blocks, each a kind followed by its markup.
  def blocks_for(article)
    blocks = ArticleBlocks.parse(article.html)

    if snippet_only?(blocks, article)
      [[:p, Text.escape(article.snippet)]]
    else
      blocks
    end
  end

  # Return the furthest the article can be scrolled.
  #
  # @return [Float] The scroll position that shows the end of the article.
  def bottom
    @scroll.vadjustment.upper - @scroll.vadjustment.page_size
  end

  # Build the column that holds the header and the content.
  #
  # @return [Gtk::Box] The column.
  def build_column
    @content = box(:vertical, 16, [])

    box(:vertical, 0, [@header.widget, @content], css: "reader-column", hexpand: true)
  end

  # Build the stack that switches between the empty state and the article.
  #
  # @return [Gtk::Stack] The stack.
  def build_stack
    stack = build(Gtk::Stack, hexpand: true, vexpand: true)

    stack.add_named(empty_state("application-rss+xml-symbolic", label("No article selected.", "empty-state")), "empty")
    stack.add_named(@scroll, "article")
    stack
  end

  # Remove the content, and free the memory of its images.
  #
  # @return [void]
  def discard_content
    freed = @fit.release

    clear(@content)

    if freed
      Memory.trim
    end
  end

  # Fill the pane with an article and scroll to the top.
  #
  # @param article [Article] The article to show.
  # @return [void]
  def display(article)
    @widget.visible_child_name = "article"
    @header.show(article)
    fill_content(article)
    @scroll.vadjustment.value = 0
  end

  # Replace the content with the widgets for the blocks of an article.
  #
  # @param article [Article] The article to show.
  # @return [void]
  def fill_content(article)
    discard_content

    widgets = BlockWidgets.new(article, downloader: @downloader, on_image: method(:add_image),
                                        still_open: -> { @article&.id == article.id })

    blocks_for(article).each { |kind, markup| @content.append(widgets.widget(kind, markup)) }
  end

  # Return whether an article has nothing to show but its snippet.
  #
  # @param blocks [Array<Array>] The blocks of the content of the article.
  # @param article [Article] The article to check.
  # @return [Boolean] Whether the content has no blocks and the snippet is not empty.
  def snippet_only?(blocks, article)
    blocks.empty? && !article.snippet.empty?
  end
end
