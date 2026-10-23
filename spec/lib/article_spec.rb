# frozen_string_literal: true

RSpec.describe Article do
  subject(:article) { described_class.new(date: date, feed: feed) }

  let(:date) { nil }
  let(:feed) { instance_double(Feed, name: "Daring Fireball") }

  describe "#dateline" do
    context "with a date" do
      let(:date) { Time.new(2020, 1, 2, 15, 4, 0) }

      it "spells out the date and the time" do
        expect(article.dateline).to eq("January 2, 2020 at 3:04 PM")
      end
    end

    context "without a date" do
      it "is empty" do
        expect(article.dateline).to eq("")
      end
    end
  end

  describe "#feed_name" do
    it "is the name of the feed" do
      expect(article.feed_name).to eq("Daring Fireball")
    end
  end
end
