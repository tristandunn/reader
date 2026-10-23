# frozen_string_literal: true

RSpec.describe Chronology do
  let(:newest)  { Article.new(id: "1", date: Time.utc(2026, 3, 1)) }
  let(:oldest)  { Article.new(id: "2", date: Time.utc(2026, 1, 1)) }
  let(:undated) { Article.new(id: "3", date: nil) }

  describe ".insert" do
    it "puts an article above the first one that is older" do
      middle   = Article.new(id: "4", date: Time.utc(2026, 2, 1))
      articles = [newest, oldest]

      described_class.insert(articles, middle)

      expect(articles).to eq([newest, middle, oldest])
    end

    it "puts an article last when none is older" do
      articles = [newest]

      described_class.insert(articles, oldest)

      expect(articles).to eq([newest, oldest])
    end

    it "puts an undated article after the dated ones" do
      articles = [newest, oldest]

      described_class.insert(articles, undated)

      expect(articles).to eq([newest, oldest, undated])
    end
  end

  describe ".newest_first" do
    it "sorts the newest first and the undated ones last" do
      expect(described_class.newest_first([undated, oldest, newest])).to eq([newest, oldest, undated])
    end
  end

  describe ".time" do
    it "is the date of an article" do
      expect(described_class.time(newest)).to eq(Time.utc(2026, 3, 1))
    end

    it "is the epoch for an undated article" do
      expect(described_class.time(undated)).to eq(Time.at(0))
    end
  end
end
