# frozen_string_literal: true

RSpec.describe ImageTag do
  let(:html) { %(<img src="a.png" width="425" height="300">) }
  let(:node) { Nokogiri::HTML5.fragment(html).at_xpath(".//img") }

  describe ".block" do
    it "holds the source and the requested width" do
      expect(described_class.block(node)).to eq(["a.png", 425])
    end

    context "without a width" do
      let(:html) { %(<img src="a.png">) }

      it "asks for no width" do
        expect(described_class.block(node)).to eq(["a.png", 0])
      end
    end
  end

  describe ".source" do
    it "is the src" do
      expect(described_class.source(node)).to eq("a.png")
    end

    context "with only a data-src" do
      let(:html) { %(<img data-src="lazy.png">) }

      it "is the data-src" do
        expect(described_class.source(node)).to eq("lazy.png")
      end
    end

    context "without a source" do
      let(:html) { "<img>" }

      it "is nil" do
        expect(described_class.source(node)).to be_nil
      end
    end
  end

  describe ".tracking_pixel?" do
    it "is false for a normal image" do
      expect(described_class.tracking_pixel?(node)).to be(false)
    end

    context "with a width of one" do
      let(:html) { %(<img src="a.png" width="1">) }

      it "is true" do
        expect(described_class.tracking_pixel?(node)).to be(true)
      end
    end

    context "with a height of two" do
      let(:html) { %(<img src="a.png" height="2">) }

      it "is true" do
        expect(described_class.tracking_pixel?(node)).to be(true)
      end
    end

    context "without sizes" do
      let(:html) { %(<img src="a.png">) }

      it "is false" do
        expect(described_class.tracking_pixel?(node)).to be(false)
      end
    end
  end

  describe ".usable?" do
    it "is true for an image with a source" do
      expect(described_class.usable?(node)).to be(true)
    end

    context "without a source" do
      let(:html) { "<img>" }

      it "is false" do
        expect(described_class.usable?(node)).to be(false)
      end
    end

    context "with a tracking pixel" do
      let(:html) { %(<img src="a.png" width="1">) }

      it "is false" do
        expect(described_class.usable?(node)).to be(false)
      end
    end
  end
end
