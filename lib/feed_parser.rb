# frozen_string_literal: true

class FeedParser
  # Create a parser for the XML of a feed.
  #
  # @param feed [Feed] The feed the XML belongs to.
  def initialize(feed)
    @feed = feed
  end

  # Read the articles of a feed, setting the title of the feed as a side effect.
  #
  # @param xml [String] The RSS or Atom XML.
  # @return [Array<Article>] The articles, up to the limit per feed, or none when the XML cannot be read.
  def parse(xml)
    document = Nokogiri::XML(xml)

    document.remove_namespaces!
    read_channel(document)
    document.xpath("//item | //entry").first(ARTICLES_PER_FEED).map { |node| article(node) }
  rescue StandardError => error
    warn "reader: #{@feed.name}: #{error.message}"
    []
  end

  private

  # Return whether a `link` element points at the article itself.
  #
  # @param link [Nokogiri::XML::Element] The `link` element.
  # @return [Boolean] Whether the link has an `href` and no relation other than alternate.
  def alternate?(link)
    !link["href"].nil? && [nil, "alternate"].include?(link["rel"])
  end

  # Build an article from an item or an entry.
  #
  # @param node [Nokogiri::XML::Element] The `item` or `entry` element.
  # @return [Article] The article.
  def article(node)
    html = first_text(node, %w(encoded content description summary)).to_s

    Article.new(date: parse_time(first_text(node, %w(pubDate published updated date))), feed: @feed, html: html,
                id: "#{@feed.url}:#{identifier(node)}", link: link_of(node), snippet: Text.snippet(html),
                title: title_of(node))
  end

  # Return the first non-empty text among some descendants.
  #
  # @param node [Nokogiri::XML::Element] The element to search.
  # @param names [Array<String>] The tags to look for, in order of preference.
  # @return [String] The text.
  # @return [nil] When none of the tags has any text.
  def first_text(node, names)
    names.map { |name| text_at(node, name) }.find { |text| !text.empty? }
  end

  # Return the home page that a feed links to.
  #
  # Atom feeds link with an `href` attribute, while RSS channels carry the URL
  # as text, beside an Atom link to the feed itself that has none.
  #
  # @param document [Nokogiri::XML::Document] The parsed XML.
  # @return [String] The URL.
  # @return [nil] When the feed links to no home page.
  def home_page(document)
    atom = document.xpath("/feed/link").find { |link| alternate?(link) }

    if atom
      atom["href"]
    else
      document.xpath("//channel/link").map { |link| link.text.strip }.find { |text| !text.empty? }
    end
  end

  # Return what identifies an item or an entry within its feed.
  #
  # @param node [Nokogiri::XML::Element] The `item` or `entry` element.
  # @return [String] The guid or ID, or the link when there is neither.
  def identifier(node)
    first_text(node, %w(guid id)) || link_of(node)
  end

  # Return the link of an item or an entry.
  #
  # Atom entries link with `href` attributes, while RSS items carry the URL
  # as text.
  #
  # @param node [Nokogiri::XML::Element] The `item` or `entry` element.
  # @return [String] The URL, which is empty when there is none.
  def link_of(node)
    links     = node.xpath("./link")
    alternate = links.find { |link| alternate?(link) }

    if alternate
      alternate["href"]
    else
      links.map { |link| link.text.strip }.find { |text| !text.empty? }.to_s
    end
  end

  # Parse a date as written in a feed.
  #
  # @param text [String, nil] The date.
  # @return [Time] The time in the local zone.
  # @return [nil] When the date cannot be parsed.
  def parse_time(text)
    Time.parse(text.to_s).localtime
  rescue ArgumentError
    nil
  end

  # Return a text unless it is empty.
  #
  # @param text [String, nil] The text that may be empty.
  # @return [String] The text.
  # @return [nil] When the text is missing or empty.
  def presence(text)
    if text.to_s.empty?
      nil
    else
      text
    end
  end

  # Give the feed what the document says about itself.
  #
  # The home page and the image are where the icon of the feed is looked for.
  #
  # @param document [Nokogiri::XML::Document] The parsed XML.
  # @return [void]
  def read_channel(document)
    title = Text.plain(document.at_xpath("/feed/title | //channel/title")&.text.to_s)

    unless title.empty?
      @feed.title = title
    end

    @feed.home_page = presence(home_page(document))
    @feed.image_url = presence(document.at_xpath("/feed/icon | /feed/logo | //channel/image/url")&.text&.strip)
  end

  # Return the text of the first matching descendant.
  #
  # @param node [Nokogiri::XML::Element] The element to search.
  # @param name [String] The tag to look for.
  # @return [String] The stripped text, which is empty when there is no such element.
  def text_at(node, name)
    node.at_xpath(".//#{name}")&.text.to_s.strip
  end

  # Return the plain-text title of an item or an entry.
  #
  # @param node [Nokogiri::XML::Element] The `item` or `entry` element.
  # @return [String] The title, or a placeholder when there is none.
  def title_of(node)
    title = text_at(node, "title")

    if title.empty?
      "(No title)"
    else
      Text.plain(title)
    end
  end
end
