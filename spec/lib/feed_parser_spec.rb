# frozen_string_literal: true

RSpec.describe FeedParser do
  subject(:parser) { described_class.new(feed) }

  let(:atom) do
    <<~XML
      <feed xmlns="http://www.w3.org/2005/Atom">
        <title>An Atom Feed</title>
        <link rel="self" href="https://example.com/feed"/>
        <link rel="alternate" href="https://example.com/"/>
        <icon>https://example.com/icon.png</icon>
        <entry>
          <title>Entry</title>
          <link rel="self" href="https://example.com/self"/>
          <link rel="alternate" href="https://example.com/entry"/>
          <id>tag:example.com,2026:1</id>
          <published>2026-10-19T10:00:00Z</published>
          <content type="html">&lt;p&gt;Hello &lt;b&gt;there&lt;/b&gt;&lt;/p&gt;</content>
        </entry>
      </feed>
    XML
  end
  let(:feed) { Feed.new("https://example.com/feed") }
  let(:rss)  do
    <<~XML
      <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
        <channel>
          <title>An RSS Feed</title>
          <atom:link xmlns:atom="http://www.w3.org/2005/Atom" rel="self" href="https://example.com/rss"/>
          <link>https://example.com/</link>
          <image><url>https://example.com/logo.png</url><title>Logo</title></image>
          <item>
            <title>Item &amp; more</title>
            <link>https://example.com/item</link>
            <guid>item-1</guid>
            <pubDate>Mon, 19 Oct 2026 10:00:00 +0000</pubDate>
            <description>Short</description>
            <content:encoded>&lt;p&gt;Long&lt;/p&gt;</content:encoded>
          </item>
        </channel>
      </rss>
    XML
  end

  describe "#parse" do
    it "reads an RSS item" do
      expect(parser.parse(rss).first).to have_attributes(
        html:  "<p>Long</p>",
        id:    "https://example.com/feed:item-1",
        link:  "https://example.com/item",
        title: "Item & more"
      )
    end

    it "reads when an RSS item was published" do
      expect(parser.parse(rss).first.date).to eq(Time.utc(2026, 10, 19, 10, 0, 0))
    end

    it "reads an Atom entry" do
      expect(parser.parse(atom).first).to have_attributes(
        html:    "<p>Hello <b>there</b></p>",
        id:      "https://example.com/feed:tag:example.com,2026:1",
        link:    "https://example.com/entry",
        snippet: "Hello there"
      )
    end

    it "gives the feed its own title" do
      parser.parse(rss)

      expect(feed.name).to eq("An RSS Feed")
    end

    it "gives the feed the title of an Atom feed" do
      parser.parse(atom)

      expect(feed.name).to eq("An Atom Feed")
    end

    it "gives the feed the home page of an RSS feed" do
      parser.parse(rss)

      expect(feed).to have_attributes(home_page: "https://example.com/", image_url: "https://example.com/logo.png")
    end

    it "gives the feed the home page of an Atom feed" do
      parser.parse(atom)

      expect(feed).to have_attributes(home_page: "https://example.com/", image_url: "https://example.com/icon.png")
    end

    it "ties the article to its feed" do
      expect(parser.parse(rss).first.feed).to be(feed)
    end

    context "without a feed title" do
      let(:rss) { "<rss><channel><item><title>A</title></item></channel></rss>" }

      it "leaves the feed named for its domain" do
        parser.parse(rss)

        expect(feed.name).to eq("example.com")
      end

      it "leaves the home page and the image unknown" do
        parser.parse(rss)

        expect(feed).to have_attributes(home_page: nil, image_url: nil)
      end
    end

    context "with an empty image URL" do
      let(:rss) { "<rss><channel><image><url> </url></image></channel></rss>" }

      it "leaves the image unknown" do
        parser.parse(rss)

        expect(feed.image_url).to be_nil
      end
    end

    context "with an item that has only a summary" do
      let(:rss) { "<rss><channel><item><title>A</title><summary>Sum</summary></item></channel></rss>" }

      it "uses the summary as the content" do
        expect(parser.parse(rss).first.html).to eq("Sum")
      end
    end

    context "with an item that has no title" do
      let(:rss) { "<rss><channel><item><link>https://example.com/x</link></item></channel></rss>" }

      it "uses a placeholder title" do
        expect(parser.parse(rss).first.title).to eq("(No title)")
      end
    end

    context "with an item that has no guid" do
      let(:rss) { "<rss><channel><item><title>A</title><link>https://example.com/x</link></item></channel></rss>" }

      it "identifies it by its link" do
        expect(parser.parse(rss).first.id).to eq("https://example.com/feed:https://example.com/x")
      end
    end

    context "with an item that has an invalid date" do
      let(:rss) { "<rss><channel><item><title>A</title><pubDate>sometime</pubDate></item></channel></rss>" }

      it "has no date" do
        expect(parser.parse(rss).first.date).to be_nil
      end
    end

    context "with an Atom entry that has only a self link" do
      let(:atom) { %(<feed><entry><title>A</title><link rel="self" href="https://example.com/self"/></entry></feed>) }

      it "has no link" do
        expect(parser.parse(atom).first.link).to eq("")
      end
    end

    context "with more items than are kept" do
      let(:rss) { "<rss><channel>#{"<item><title>A</title></item>" * 3}</channel></rss>" }

      before do
        stub_const("ARTICLES_PER_FEED", 2)
      end

      it "keeps only the first ones" do
        expect(parser.parse(rss).size).to eq(2)
      end
    end

    context "when reading fails" do
      include_context "with captured warnings"

      before do
        allow(Text).to receive(:plain).and_raise(StandardError.new("broken"))
      end

      it "returns no articles" do
        expect(parser.parse(rss)).to eq([])
      end

      it "warns about the failure" do
        parser.parse(rss)

        expect(Warning).to have_received(:warn).with(a_string_including("broken"), any_args)
      end
    end
  end
end
