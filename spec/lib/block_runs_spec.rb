# frozen_string_literal: true

RSpec.describe BlockRuns do
  describe ".combine" do
    it "combines a run of quotes into one quote" do
      expect(described_class.combine([[:quote, "a"], [:quote, "b"]])).to eq([:quote, %w(a b)])
    end

    it "combines a run of list items into a list" do
      expect(described_class.combine([[:li, "a"], [:li, "b"]])).to eq([:list, %w(a b)])
    end

    it "leaves any other block alone" do
      expect(described_class.combine([[:p, "a"]])).to eq([:p, "a"])
    end
  end

  describe ".merge" do
    it "merges consecutive quotes but not ones split by a paragraph" do
      blocks = [[:quote, "a"], [:quote, "b"], [:p, "c"], [:quote, "d"]]

      expect(described_class.merge(blocks)).to eq([[:quote, %w(a b)], [:p, "c"], [:quote, ["d"]]])
    end

    it "keeps consecutive paragraphs separate" do
      expect(described_class.merge([[:p, "a"], [:p, "b"]])).to eq([[:p, "a"], [:p, "b"]])
    end
  end

  describe ".mergeable?" do
    it "is true for two quotes" do
      expect(described_class.mergeable?([:quote, "a"], [:quote, "b"])).to be(true)
    end

    it "is false for two paragraphs" do
      expect(described_class.mergeable?([:p, "a"], [:p, "b"])).to be(false)
    end

    it "is false for different kinds" do
      expect(described_class.mergeable?([:quote, "a"], [:li, "b"])).to be(false)
    end
  end
end
