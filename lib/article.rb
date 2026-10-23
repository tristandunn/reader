# frozen_string_literal: true

Article = Struct.new(:id, :feed, :title, :link, :html, :snippet, :date, keyword_init: true) do
  # Return the date shown under the title in the reading pane.
  #
  # @return [String] The date and time spelled out, which is empty without a date.
  def dateline
    if date
      date.strftime("%B %-d, %Y at %-l:%M %p")
    else
      ""
    end
  end

  # Return the name of the feed the article came from.
  #
  # @return [String] The name of the feed.
  def feed_name
    feed.name
  end
end
