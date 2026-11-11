# frozen_string_literal: true

RSpec.describe VideoTag do
  let(:node) { Nokogiri::HTML5.fragment(html).children.first }

  describe ".source" do
    subject(:source) { described_class.source(node) }

    context "with a source on the video" do
      let(:html) { %(<video src="https://example.com/a.mp4"></video>) }

      it "is the source" do
        expect(source).to eq("https://example.com/a.mp4")
      end
    end

    context "with a source element" do
      let(:html) { %(<video><source src=" https://example.com/b.mp4 "></video>) }

      it "is the source of that element" do
        expect(source).to eq("https://example.com/b.mp4")
      end
    end

    context "with a relative source" do
      let(:html) { %(<video src="a.mp4"></video>) }

      it "is the source as written" do
        expect(source).to eq("a.mp4")
      end
    end

    context "without a source" do
      let(:html) { "<video></video>" }

      it "is nil" do
        expect(source).to be_nil
      end
    end
  end
end
