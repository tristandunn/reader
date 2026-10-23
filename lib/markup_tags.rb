# frozen_string_literal: true

module MarkupTags
  SKIPPED = %w(script style iframe svg video audio form button).freeze

  CONTAINERS = %w(p div section article figure figcaption ul ol dl dd dt
                  header footer main aside tbody thead tfoot tr td th).freeze

  # A translucent gray reads as a tint on a light page and on a dark one.
  CODE = "<span font_family='monospace' size='92%' background='#8e8e93' bgalpha='18%'>"

  INLINE = {
    "br"     => ["\n", ""],
    "b"      => ["<b>", "</b>"],
    "strong" => ["<b>", "</b>"],
    "i"      => ["<i>", "</i>"],
    "em"     => ["<i>", "</i>"],
    "cite"   => ["<i>", "</i>"],
    "u"      => ["<u>", "</u>"],
    "s"      => ["<s>", "</s>"],
    "del"    => ["<s>", "</s>"],
    "sup"    => ["<sup>", "</sup>"],
    "sub"    => ["<sub>", "</sub>"],
    "code"   => [CODE, "</span>"],
    "tt"     => [CODE, "</span>"]
  }.freeze

  HEADING = /\Ah[1-6]\z/

  CONTEXTS = { "li" => :li, "blockquote" => :quote }.freeze

  HANDLERS = { "pre" => :pre, "img" => :image, "table" => :table, "a" => :link }.freeze
end
