# frozen_string_literal: true

RSpec.describe Text do
  describe ".escape" do
    it "escapes ampersands and angle brackets" do
      expect(described_class.escape("a & b < c > d")).to eq("a &amp; b &lt; c &gt; d")
    end
  end

  describe ".plain" do
    it "strips tags and collapses whitespace" do
      expect(described_class.plain("<p>One\n  <b>two</b></p>")).to eq("One two")
    end
  end

  describe ".short_date" do
    let(:now) { Time.new(2026, 10, 21, 12, 0, 0) }

    before do
      allow(Time).to receive(:now).and_return(now)
    end

    it "returns nothing for nil" do
      expect(described_class.short_date(nil)).to eq("")
    end

    it "shows the time for today" do
      expect(described_class.short_date(Time.new(2026, 10, 21, 9, 5, 0))).to eq("9:05 AM")
    end

    it "says Yesterday for the day before" do
      expect(described_class.short_date(Time.new(2026, 10, 20, 23, 0, 0))).to eq("Yesterday")
    end

    it "shows the month and day earlier this year" do
      expect(described_class.short_date(Time.new(2026, 3, 3, 8, 0, 0))).to eq("Mar 3")
    end

    it "adds the year for other years" do
      expect(described_class.short_date(Time.new(2025, 3, 3, 8, 0, 0))).to eq("Mar 3, 2025")
    end
  end

  describe ".snippet" do
    it "drops bare URLs" do
      expect(described_class.snippet("<p>See https://example.com/a now</p>")).to eq("See now")
    end

    it "reads the whole article when its start holds too little text" do
      html = "<div>#{"<b></b>" * SNIPPET_SOURCE_LENGTH}</div><p>Late text</p>"

      expect(described_class.snippet(html)).to eq("Late text")
    end

    it "reads only the start of a long article" do
      html = "<p>#{"a" * SNIPPET_LENGTH} #{"b" * SNIPPET_SOURCE_LENGTH}</p>"

      allow(described_class).to receive(:plain).and_call_original
      described_class.snippet(html)

      expect(described_class).to have_received(:plain).once
    end

    it "truncates to the snippet length" do
      expect(described_class.snippet("a" * 200).length).to eq(SNIPPET_LENGTH)
    end
  end
end
