# frozen_string_literal: true

RSpec.describe IconLinks do
  describe ".candidates" do
    let(:base) { "https://example.com/blog/" }

    def candidates(head)
      described_class.candidates("<html><head>#{head}</head></html>", base)
    end

    it "prefers a touch icon to a PNG icon" do
      head = '<link rel="icon" href="/small.png"><link rel="apple-touch-icon" href="/touch.png">'

      expect(candidates(head)).to eq(%w(https://example.com/touch.png https://example.com/small.png))
    end

    it "accepts a precomposed touch icon" do
      expect(candidates('<link rel="apple-touch-icon-precomposed" href="t.png">')).to eq(["https://example.com/blog/t.png"])
    end

    it "accepts an icon declared as PNG" do
      expect(candidates('<link rel="Shortcut Icon" type="image/png" href="/icon">')).to eq(["https://example.com/icon"])
    end

    it "accepts an icon with a query after its extension" do
      expect(candidates('<link rel="icon" href="/icon.PNG?v=2">')).to eq(["https://example.com/icon.PNG?v=2"])
    end

    it "skips an icon that cannot be decoded, such as ICO or SVG" do
      expect(candidates('<link rel="icon" href="/favicon.ico"><link rel="icon" href="/i.svg">')).to eq([])
    end

    it "skips a link that is not an icon" do
      expect(candidates('<link rel="stylesheet" href="/site.png">')).to eq([])
    end

    it "skips a link that is not on the web" do
      expect(candidates('<link rel="apple-touch-icon" href="data:image/png;base64,AAAA">')).to eq([])
    end

    it "skips a link that cannot be parsed" do
      expect(candidates('<link rel="apple-touch-icon" href="http://[bad">')).to eq([])
    end

    it "lists a URL once" do
      head = '<link rel="apple-touch-icon" href="/t.png"><link rel="icon" href="/t.png">'

      expect(candidates(head)).to eq(["https://example.com/t.png"])
    end
  end

  describe ".favicon" do
    it "returns the default location at the root of the site" do
      expect(described_class.favicon("https://example.com/blog/")).to eq("https://example.com/favicon.ico")
    end

    it "returns nothing for a home page that cannot be parsed" do
      expect(described_class.favicon("http://[bad")).to be_nil
    end
  end
end
