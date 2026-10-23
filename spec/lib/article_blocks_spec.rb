# frozen_string_literal: true

RSpec.describe ArticleBlocks do
  describe ".parse" do
    it "parses the HTML" do
      expect(described_class.parse("<p>One</p>")).to eq([[:p, "One"]])
    end
  end

  describe "#parse" do
    subject(:blocks) { described_class.new.parse(html) }

    let(:html) { "<p>One</p><p>Two</p>" }

    it "makes a block of each paragraph" do
      expect(blocks).to eq([[:p, "One"], [:p, "Two"]])
    end

    context "with no content" do
      let(:html) { "" }

      it "has no blocks" do
        expect(blocks).to eq([])
      end
    end

    context "with headings" do
      let(:html) { "<h2>Title</h2><p>Text</p>" }

      it "marks them as headings" do
        expect(blocks).to eq([[:h, "Title"], [:p, "Text"]])
      end
    end

    context "with inline formatting" do
      let(:html) { "<p><strong>a</strong> <em>b</em> <code>c</code></p>" }

      it "keeps it as Pango markup" do
        expect(blocks).to eq([[:p, "<b>a</b> <i>b</i> #{MarkupTags::CODE}c</span>"]])
      end
    end

    context "with text that Pango would mistake for markup" do
      let(:html) { "<p>a &amp; b &lt; c</p>" }

      it "escapes it" do
        expect(blocks).to eq([[:p, "a &amp; b &lt; c"]])
      end
    end

    context "with a line break" do
      let(:html) { "<p>One<br>Two</p>" }

      it "keeps the break" do
        expect(blocks).to eq([[:p, "One\nTwo"]])
      end
    end

    context "with an http link" do
      let(:html) { %(<p>See <a href="https://example.com/?a=1&amp;b=2">this</a>.</p>) }

      it "keeps the link" do
        expect(blocks).to eq([[:p, %(See <a href="https://example.com/?a=1&amp;b=2">this</a>.)]])
      end
    end

    context "with a link that does not go to the web" do
      let(:html) { %(<p><a href="mailto:me@example.com">mail</a></p>) }

      it "keeps only the text" do
        expect(blocks).to eq([[:p, "mail"]])
      end
    end

    context "with a link around an image" do
      let(:html) { %(<a href="https://example.com"><img src="a.png" width="425"></a>) }

      it "keeps the image without the link" do
        expect(blocks).to eq([[:image, ["a.png", 425]]])
      end
    end

    context "with an image" do
      let(:html) { %(<p>Before</p><img data-src="b.png"><p>After</p>) }

      it "splits the text around it" do
        expect(blocks).to eq([[:p, "Before"], [:image, ["b.png", 0]], [:p, "After"]])
      end
    end

    context "with a tracking pixel" do
      let(:html) { %(<p>Text</p><img src="t.gif" width="1" height="1">) }

      it "leaves it out" do
        expect(blocks).to eq([[:p, "Text"]])
      end
    end

    context "with a code block" do
      let(:html) { "<pre>  a &lt; b\n  c</pre>" }

      it "keeps the whitespace, without hyphens where a long line wraps" do
        expect(blocks).to eq([[:pre, "<span insert_hyphens='false'>a &lt; b\n  c</span>"]])
      end
    end

    context "with a list" do
      let(:html) { "<ul><li>One</li><li>Two</li></ul>" }

      it "merges the items" do
        expect(blocks).to eq([[:list, %w(One Two)]])
      end
    end

    context "with a blockquote of two paragraphs" do
      let(:html) { "<blockquote><p>One</p><p>Two</p></blockquote>" }

      it "merges the paragraphs" do
        expect(blocks).to eq([[:quote, %w(One Two)]])
      end
    end

    context "with a table" do
      let(:html) { "<table><tr><th>A</th></tr><tr><td>1</td></tr></table>" }

      it "reads the rows" do
        expect(blocks).to eq([[:table, [["<b>A</b>"], ["1"]]]])
      end
    end

    context "with a table that only lays out content" do
      let(:html) do
        "<table><tr><td><p>One</p></td><td><table><tr><td><h2>Two</h2></td></tr></table></td></tr></table>"
      end

      it "flows the content as ordinary blocks" do
        expect(blocks).to eq([[:p, "One"], [:h, "Two"]])
      end
    end

    context "with a table whose cell holds a long run of text" do
      let(:html) { "<table><tr><td>#{"word " * 40}</td></tr></table>" }

      it "flows the text as a paragraph" do
        expect(blocks).to eq([[:p, "#{"word " * 39}word"]])
      end
    end

    context "with a table that holds nothing" do
      let(:html) { "<p>Before</p><table><tr><td></td></tr></table><p>After</p>" }

      it "leaves it out" do
        expect(blocks).to eq([[:p, "Before"], [:p, "After"]])
      end
    end

    context "with nested containers" do
      let(:html) { "<div>One<div>Two</div></div>" }

      it "ends the text at each container" do
        expect(blocks).to eq([[:p, "One"], [:p, "Two"]])
      end
    end

    context "with scripts, styles and comments" do
      let(:html) { "<p>Text</p><script>alert(1)</script><style>p {}</style><!-- note -->" }

      it "leaves them out" do
        expect(blocks).to eq([[:p, "Text"]])
      end
    end

    context "with an unknown tag" do
      let(:html) { "<p>a <span>b</span> c</p>" }

      it "keeps its text" do
        expect(blocks).to eq([[:p, "a b c"]])
      end
    end
  end
end
