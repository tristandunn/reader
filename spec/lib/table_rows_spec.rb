# frozen_string_literal: true

RSpec.describe TableRows do
  let(:table) { Nokogiri::HTML5.fragment(html).at_xpath(".//table") }

  describe ".bold?" do
    let(:cell) { Nokogiri::HTML5.fragment("<table><tr><th>A</th></tr></table>").at_xpath(".//th") }

    it "is true for a header cell with text" do
      expect(described_class.bold?(cell, "A")).to be(true)
    end

    it "is false for a header cell without text" do
      expect(described_class.bold?(cell, "")).to be(false)
    end
  end

  describe ".data?" do
    context "with plain cells" do
      let(:html) { "<table><tr><th>Name</th></tr><tr><td>Duo <em>254g</em></td></tr></table>" }

      it "is true" do
        expect(described_class.data?(table)).to be(true)
      end
    end

    context "with a table inside a cell" do
      let(:html) { "<table><tr><td><table><tr><td>Inner</td></tr></table></td></tr></table>" }

      it "is false" do
        expect(described_class.data?(table)).to be(false)
      end
    end

    context "with a paragraph inside a cell" do
      let(:html) { "<table><tr><td><p>Text</p></td></tr></table>" }

      it "is false" do
        expect(described_class.data?(table)).to be(false)
      end
    end

    context "with a cell of exactly the longest text a grid takes" do
      let(:html) { "<table><tr><td>#{"a" * TABLE_CELL_MAX_CHARS}</td></tr></table>" }

      it "is true" do
        expect(described_class.data?(table)).to be(true)
      end
    end

    context "with a cell of text longer than a grid takes" do
      let(:html) { "<table><tr><td>#{"a" * (TABLE_CELL_MAX_CHARS + 1)}</td><td>b</td></tr></table>" }

      it "is false" do
        expect(described_class.data?(table)).to be(false)
      end
    end

    context "with long text broken by line breaks" do
      let(:html) { "<table><tr><td>#{"word<br>" * 40}</td></tr></table>" }

      it "is false" do
        expect(described_class.data?(table)).to be(false)
      end
    end

    context "with no text in any cell" do
      let(:html) { "<table><tr><td> </td><td></td></tr></table>" }

      it "is false" do
        expect(described_class.data?(table)).to be(false)
      end
    end

    context "with an image inside a cell" do
      let(:html) { %(<table><tr><td><img src="a.png"></td></tr></table>) }

      it "is false" do
        expect(described_class.data?(table)).to be(false)
      end
    end
  end

  describe ".markup" do
    let(:cell) { Nokogiri::HTML5.fragment("<table><tr><td>One <em>two</em></td></tr></table>").at_xpath(".//td") }

    it "keeps inline formatting" do
      expect(described_class.markup(cell)).to eq("One <i>two</i>")
    end
  end

  describe ".parse" do
    let(:html) do
      "<table><tr><th>Name</th><th></th></tr><tr><td>Duo</td><td>254g</td></tr><tr><td></td><td></td></tr></table>"
    end

    it "bolds header cells and drops empty rows" do
      expect(described_class.parse(table)).to eq([["<b>Name</b>", ""], %w(Duo 254g)])
    end
  end
end
