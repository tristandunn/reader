# frozen_string_literal: true

module MarkupTags
  CODE = "<span font_family='monospace' size='92%' background='#8e8e93' bgalpha='18%'>"

  CONTAINERS = %w(p div section article figure figcaption ul ol dl dd dt
                  header footer main aside tbody thead tfoot tr td th).freeze

  CONTEXTS = { "li" => :li, "blockquote" => :quote }.freeze

  HANDLERS = {
    "a"     => :link,
    "img"   => :image,
    "pre"   => :pre,
    "table" => :table,
    "video" => :video
  }.freeze

  HEADING = /\Ah[1-6]\z/

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

  SKIPPED = %w(script style iframe svg audio form button).freeze
end
