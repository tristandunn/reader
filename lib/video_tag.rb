# frozen_string_literal: true

module VideoTag
  module_function

  # Return the source of the file of a video.
  #
  # The source is either on the element or on its first `source` child. It may
  # be relative to the article.
  #
  # @param node [Nokogiri::XML::Element] The `video` element.
  # @return [String] The source.
  # @return [nil] When the video has no source.
  def source(node)
    value = (node["src"] || node.at_xpath(".//source")&.[]("src")).to_s.strip

    if value.empty?
      nil
    else
      value
    end
  end
end
