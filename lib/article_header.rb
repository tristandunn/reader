# frozen_string_literal: true

class ArticleHeader
  include Ui

  attr_reader :widget

  # Build the header of the reading pane: the icon and name of the feed, the
  # title, the date, and a rule above the content.
  def initialize
    @avatar = FeedAvatar.new(20, large: true)
    @source = label("", "reader-source", ellipsize: :end, valign: :center)
    @title  = label("", "reader-title", can_focus: false, max_width_chars: 36, selectable: true, wrap: true,
                                        wrap_mode: :word_char)
    @date   = label("", "reader-date")
    @widget = box(:vertical, 6, [source_line, @title, @date, box(:vertical, 0, [], css: "reader-rule")])
  end

  # Show the header of an article.
  #
  # @param article [Article] The article to show.
  # @return [void]
  def show(article)
    @avatar.show(article.feed)
    @source.text = article.feed_name
    @title.text  = article.title
    @date.text   = article.dateline
  end

  private

  # Build the line above the title, with the icon and the name of the feed.
  #
  # @return [Gtk::Box] The line.
  def source_line
    box(:horizontal, 8, [@avatar.widget, @source], margin_bottom: 10)
  end
end
