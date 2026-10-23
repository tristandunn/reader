# frozen_string_literal: true

module IconLinks
  PNG        = /\.png(\?|\z)/i
  TOUCH_ICON = /\Aapple-touch-icon/

  module_function

  # Return the icons that a home page links to, best first.
  #
  # The links are found with XPath rather than CSS, because the selector that
  # Nokogiri builds from CSS is refused by the newer libxml2 that GTK loads.
  #
  # A touch icon is large and square, so it stays sharp when scaled down. Only
  # PNG icons are listed, because GTK hands ICO and SVG files to a loader that
  # is not always available.
  #
  # @param html [String] The HTML of the home page.
  # @param base [String] The URL of the home page, which relative links are resolved against.
  # @return [Array<String>] The URLs of the icons.
  def candidates(html, base)
    links = Nokogiri::HTML5(html).xpath("//link[@rel and @href]")
    touch = links.select { |link| rels(link).any?(TOUCH_ICON) }
    icons = links.select { |link| rels(link).include?("icon") && png?(link) }

    (touch + icons).filter_map { |link| resolve(base, link["href"]) }.uniq
  end

  # Return the default location of the icon of a site.
  #
  # Many sites link no icon and only serve this file, which is usually ICO.
  # GTK decodes ICO through its image loaders, so it is tried last.
  #
  # @param base [String] The URL of the home page.
  # @return [String] The URL at the root of the site.
  # @return [nil] When the home page is not on the web, or cannot be parsed.
  def favicon(base)
    resolve(base, "/favicon.ico")
  end

  # Return whether a link declares a PNG image.
  #
  # @param link [Nokogiri::XML::Element] The `link` element.
  # @return [Boolean] Whether the type is PNG or the URL ends in `.png`.
  def png?(link)
    link["type"] == "image/png" || link["href"].match?(PNG)
  end

  # Return the relations of a link.
  #
  # @param link [Nokogiri::XML::Element] The `link` element.
  # @return [Array<String>] The lowercase relations, such as `shortcut` and `icon`.
  def rels(link)
    link["rel"].downcase.split
  end

  # Resolve a link against the home page.
  #
  # @param base [String] The URL of the home page.
  # @param href [String] The link.
  # @return [String] The URL.
  # @return [nil] When the URL is not http or https, or cannot be parsed.
  def resolve(base, href)
    url = URI.join(base, href.strip).to_s

    if url.match?(%r{\Ahttps?://}i)
      url
    end
  rescue URI::Error
    nil
  end
end
