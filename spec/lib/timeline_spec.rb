# frozen_string_literal: true

RSpec.describe Timeline do
  subject(:timeline) { described_class.new(articles, state) }

  let(:articles) { Array.new(4) { |index| Article.new(id: index.to_s) } }
  let(:state)    { ReadState.new("missing.yml") }

  describe "#above" do
    it "returns the articles listed before an article" do
      expect(timeline.above(articles[2])).to eq(articles[0, 2])
    end

    it "returns nothing for an article that is not listed" do
      expect(timeline.above(Article.new(id: "missing"))).to eq([])
    end
  end

  describe "#below" do
    it "returns the articles listed after an article" do
      expect(timeline.below(articles[1])).to eq(articles[2, 2])
    end

    it "returns nothing for an article that is not listed" do
      expect(timeline.below(Article.new(id: "missing"))).to eq([])
    end
  end

  describe "#find" do
    it "returns the article with an ID" do
      expect(timeline.find("2")).to be(articles[2])
    end

    it "returns nothing for an unknown ID" do
      expect(timeline.find("missing")).to be_nil
    end
  end

  describe "#index" do
    it "finds a copy of an article by its ID" do
      expect(timeline.index(Article.new(id: "3"))).to eq(3)
    end

    it "returns nothing without an article" do
      expect(timeline.index(nil)).to be_nil
    end
  end

  describe "#next_unread" do
    before do
      [articles[0], articles[2]].each { |article| state.mark_read(article, true) }
    end

    it "returns the first unread article below an article" do
      expect(timeline.next_unread(articles[1])).to be(articles[3])
    end

    it "wraps around to the top" do
      expect(timeline.next_unread(articles[3])).to be(articles[1])
    end

    it "starts at the top without an article" do
      expect(timeline.next_unread(nil)).to be(articles[1])
    end

    it "returns nothing when only the article itself is unread" do
      state.mark_read(articles[3], true)

      expect(timeline.next_unread(articles[1])).to be_nil
    end
  end

  describe "#unread_count" do
    it "counts the unread articles" do
      state.mark_read(articles[0], true)

      expect(timeline.unread_count).to eq(3)
    end
  end
end
