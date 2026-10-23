# frozen_string_literal: true

class ArticleRow
  include Ui

  attr_reader :article, :widget

  # Build an empty row, which the article list fills with one article after
  # another as it scrolls.
  #
  # The row has an unread dot and a star, the icon of the feed, the title, the
  # snippet, and the source and date.
  #
  # @param state [ReadState] What decides how the row is styled.
  # @param menu [RowMenu] What pops up on a right-click.
  def initialize(state, menu:)
    @state   = state
    @menu    = menu
    @article = nil
    @avatar  = FeedAvatar.new(18)
    @widget  = box(:horizontal, 0, [gutter, avatar_column, text_column])
    add_click
  end

  # Fill the row with an article.
  #
  # @param article [Article] The article to show.
  # @return [void]
  def bind(article)
    @article = article
    show_text
    @avatar.show(article.feed)
    restyle
  end

  # Update the read and starred styling to match the state.
  #
  # @return [void]
  def restyle
    read = @state.read?(@article)

    toggle_class(@widget, "read", read)
    @dot.opacity  = read ? 0 : 1
    @star.visible = @state.starred?(@article)
  end

  private

  # Pop up the menu of the article on a right-click.
  #
  # @return [void]
  def add_click
    click = Gtk::GestureClick.new
    click.button = 3 # secondary

    click.signal_connect("pressed") do |_gesture, _presses, x_pos, y_pos|
      if @article
        @menu.popup(@article, @widget, x_pos, y_pos)
      end
    end
    @widget.add_controller(click)
  end

  # Build the column that holds the icon of the feed.
  #
  # @return [Gtk::Box] The column.
  def avatar_column
    box(:vertical, 0, [@avatar.widget], css: "article-avatar")
  end

  # Build the column of marks on the left, with the unread dot above the star.
  #
  # The dot is hidden by making it clear rather than invisible, so that the
  # star below it does not move up.
  #
  # @return [Gtk::Box] The column.
  def gutter
    @dot  = build(Gtk::Box, :horizontal, 0, css: "unread-dot", halign: :center)
    @star = build(Gtk::Image, css: "star-mark", halign: :center, icon_name: "starred-symbolic", pixel_size: 10)

    box(:vertical, 6, [@dot, @star], css: "article-gutter")
  end

  # Build the source on the left and the date on the right.
  #
  # @return [Gtk::Box] The line.
  def meta_line
    @source = label("", "article-source", ellipsize: :end, hexpand: true)
    @date   = label("", "article-date", xalign: 1.0)

    box(:horizontal, 8, [@source, @date])
  end

  # Fill the labels with the text of the article.
  #
  # @return [void]
  def show_text
    @title.text      = @article.title
    @snippet.text    = @article.snippet
    @snippet.visible = !@article.snippet.empty?
    @source.text     = @article.feed_name
    @date.text       = Text.short_date(@article.date)
  end

  # Build the column of text, whose bottom border separates it from the next
  # row.
  #
  # @return [Gtk::Box] The column.
  def text_column
    @title   = label("", "article-title", ellipsize: :end, lines: 2, wrap: true, wrap_mode: :word_char)
    @snippet = label("", "article-snippet", ellipsize: :end, lines: 2, wrap: true, wrap_mode: :word_char)

    box(:vertical, 3, [@title, @snippet, meta_line], css: "article-text", hexpand: true)
  end
end
