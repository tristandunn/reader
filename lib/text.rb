# frozen_string_literal: true

module Text
  module_function

  # Escape text for use in Pango markup.
  #
  # @param text [String] The text to escape.
  # @return [String] The escaped text.
  def escape(text)
    text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end

  # Format a time relative to today.
  #
  # @param time [Time] The time to format.
  # @return [String] The short form.
  def format_date(time)
    today = Time.now.to_date

    if time.to_date == today
      time.strftime("%-l:%M %p")
    elsif time.to_date == today - 1
      "Yesterday"
    elsif time.year == today.year
      time.strftime("%b %-d")
    else
      time.strftime("%b %-d, %Y")
    end
  end

  # Return whether the start of an article is too short to find a snippet in.
  #
  # @param html [String] The whole article.
  # @param text [String] The text found in the start of the article.
  # @return [Boolean] Whether the article goes on past its start, and the text from the start is not enough.
  def lacks_text?(html, text)
    html.length > SNIPPET_SOURCE_LENGTH && text.length < SNIPPET_LENGTH + SNIPPET_SLACK
  end

  # Strip HTML down to plain text with collapsed whitespace.
  #
  # @param html [String] The HTML fragment.
  # @return [String] The text it contains.
  def plain(html)
    Nokogiri::HTML5.fragment(html).text.gsub(/\s+/, " ").strip
  end

  # Strip HTML down to one line of plain text without bare URLs.
  #
  # @param html [String] The HTML fragment.
  # @return [String] The text, which is not cut to a length.
  def preview(html)
    plain(html).gsub(%r{https?://\S+}, "").gsub(/\s+/, " ").strip
  end

  # Format a time as 6:59 PM for today, then as Yesterday, Oct 19 or Oct
  # 19, 2025.
  #
  # @param time [Time, nil] The time to format.
  # @return [String] The short form, which is empty for nil.
  def short_date(time)
    if time.nil?
      ""
    else
      format_date(time)
    end
  end

  # Return one line of preview text.
  #
  # Bare URLs carry no information in a list, so they are dropped.
  #
  # Only the start of the article is parsed, since a snippet is short and
  # parsing every article in full dominated the time to open the application.
  # The whole article is parsed when the start holds too little text, which
  # includes room for the end of it being cut off.
  #
  # @param html [String] The HTML fragment.
  # @return [String] The text, cut to the snippet length.
  def snippet(html)
    text = preview(html[0, SNIPPET_SOURCE_LENGTH])

    if lacks_text?(html, text)
      text = preview(html)
    end

    text[0, SNIPPET_LENGTH]
  end
end
