# frozen_string_literal: true

class ArticleBlocks
  include MarkupTags

  # Create an empty set of blocks.
  def initialize
    @blocks  = []
    @buffer  = +""
    @context = :p
  end

  # Split HTML into blocks.
  #
  # @param html [String] The HTML fragment.
  # @return [Array<Array>] The blocks, in document order, each a kind followed by its markup.
  def self.parse(html)
    new.parse(html)
  end

  # Split HTML into blocks.
  #
  # @param html [String] The HTML fragment.
  # @return [Array<Array>] The blocks, in document order, each a kind followed by its markup.
  def parse(html)
    Nokogiri::HTML5.fragment(html).children.each { |node| walk(node) }
    flush
    BlockRuns.merge(@blocks)
  end

  private

  # Walk each child of a node.
  #
  # @param node [Nokogiri::XML::Node] The parent node.
  # @return [void]
  def children(node)
    node.children.each { |child| walk(child) }
  end

  # Return the kind of block that the text of a tag becomes.
  #
  # @param name [String] The name of the tag.
  # @return [Symbol] The kind of block.
  # @return [nil] When the tag starts no block.
  def context_for(name)
    if name.match?(HEADING)
      :h
    elsif CONTAINERS.include?(name)
      @context
    else
      CONTEXTS[name]
    end
  end

  # Turn the text gathered so far into a block of the current kind.
  #
  # @return [void]
  def flush
    text = @buffer.gsub(/ *\n */, "\n").strip

    @blocks << [@context, text] unless text.empty?
    @buffer.clear
  end

  # Emit an image block.
  #
  # Nothing is emitted for an image without a source or for a tracking pixel.
  #
  # @param node [Nokogiri::XML::Element] The `img` element.
  # @return [void]
  def image(node)
    if ImageTag.usable?(node)
      flush
      @blocks << [:image, ImageTag.block(node)]
    end
  end

  # Wrap the children of a node in opening and closing Pango tags.
  #
  # @param node [Nokogiri::XML::Node] The node to wrap.
  # @param open [String] The opening tag.
  # @param close [String] The closing tag.
  # @return [void]
  def inline(node, open, close)
    @buffer << open
    children(node)
    @buffer << close
  end

  # Wrap the children of a node in an `a` tag when the link should be kept.
  #
  # @param node [Nokogiri::XML::Element] The `a` element.
  # @return [void]
  def link(node)
    if linkable?(node)
      inline(node, "<a href=\"#{Text.escape(node["href"]).gsub('"', "&quot;")}\">", "</a>")
    else
      children(node)
    end
  end

  # Return whether a link should be kept.
  #
  # An image inside a link would end the running text block, which would split
  # the tags of the link.
  #
  # @param node [Nokogiri::XML::Element] The `a` element.
  # @return [Boolean] Whether the link goes to the web and has no image inside.
  def linkable?(node)
    node["href"].to_s.match?(%r{\Ahttps?://}i) && node.at_xpath(".//img").nil?
  end

  # Emit a code block that keeps its whitespace.
  #
  # Pango adds a hyphen where it breaks a word to wrap a line, which in code
  # would read as part of the code, so the hyphens are turned off.
  #
  # @param node [Nokogiri::XML::Element] The `pre` element.
  # @return [void]
  def pre(node)
    flush
    @blocks << [:pre, "<span insert_hyphens='false'>#{Text.escape(node.text.strip)}</span>"]
  end

  # Emit a table block, which is laid out as a grid later.
  #
  # A table that only lays out content has no grid, and its content flows.
  #
  # @param node [Nokogiri::XML::Element] The `table` element.
  # @return [void]
  def table(node)
    if TableRows.data?(node)
      flush
      @blocks << [:table, TableRows.parse(node)]
    else
      within(@context) { children(node) }
    end
  end

  # Add the text of a node to the running text, or dispatch on its tag.
  #
  # @param node [Nokogiri::XML::Node] The node to walk.
  # @return [void]
  def walk(node)
    if node.text?
      @buffer << Text.escape(node.text.gsub(/\s+/, " "))
    elsif node.element?
      walk_element(node)
    end
  end

  # Handle an element according to its tag.
  #
  # @param node [Nokogiri::XML::Element] The element to walk.
  # @return [void]
  def walk_element(node)
    if HANDLERS.key?(node.name)
      send(HANDLERS[node.name], node)
    else
      walk_markup(node)
    end
  end

  # Skip, wrap or descend into an element that has no handler of its own.
  #
  # @param node [Nokogiri::XML::Element] The element to walk.
  # @return [void]
  def walk_markup(node)
    context = context_for(node.name)

    if SKIPPED.include?(node.name)
      nil
    elsif context
      within(context) { children(node) }
    elsif INLINE.key?(node.name)
      inline(node, *INLINE[node.name])
    else
      children(node)
    end
  end

  # Run a block with text becoming blocks of the given kind.
  #
  # @param context [Symbol] The kind of block to emit.
  # @yield Walk the content.
  # @return [void]
  def within(context)
    flush
    previous = @context

    @context = context
    yield
    flush
    @context = previous
  end
end
