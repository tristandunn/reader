# frozen_string_literal: true

RSpec.describe Library do
  subject(:library) { described_class.new([beta, alpha], state) }

  let(:alpha)    { instance_double(Feed, name: "alpha") }
  let(:articles) do
    {
      newest:  Article.new(id: "3", feed: beta, date: Time.utc(2026, 3, 1)),
      oldest:  Article.new(id: "1", feed: alpha, date: Time.utc(2026, 1, 1)),
      undated: Article.new(id: "2", feed: alpha, date: nil)
    }
  end
  let(:beta)     { instance_double(Feed, name: "Beta") }
  let(:state)    { ReadState.new("missing.yml") }

  before do
    allow(Time).to receive(:now).and_return(Time.utc(2026, 3, 15))
    allow(state).to receive(:save)
    allow(alpha).to receive(:articles).with(refresh: false).and_return(articles.values_at(:oldest, :undated))
    allow(beta).to receive(:articles).with(refresh: false).and_return([articles[:newest]])
    library.replace(library.load(refresh: false))
  end

  def entry(title)
    library.entries.find { |candidate| candidate.title == title }
  end

  describe "#articles_for" do
    it "lists the unread articles for All Unread" do
      state.mark_read(articles[:oldest], true)

      expect(library.articles_for(entry("All Unread"))).to eq(articles.values_at(:newest, :undated))
    end

    it "lists the articles of the past day for Today" do
      recent = Article.new(id: "4", feed: beta, date: Time.utc(2026, 3, 14, 1))

      library.replace([recent, *articles.values])

      expect(library.articles_for(entry("Today"))).to eq([recent])
    end

    it "lists the starred articles for Starred" do
      state.toggle_star(articles[:undated])

      expect(library.articles_for(entry("Starred"))).to eq([articles[:undated]])
    end

    it "lists the articles of a feed for its entry" do
      expect(library.articles_for(entry("alpha"))).to eq(articles.values_at(:oldest, :undated))
    end

    it "lists read articles by default" do
      state.mark_read(articles[:oldest], true)

      expect(library.articles_for(entry("alpha"))).to eq(articles.values_at(:oldest, :undated))
    end

    it "leaves out read articles when asked to hide them" do
      state.mark_read(articles[:oldest], true)

      expect(library.articles_for(entry("alpha"), hide_read: true)).to eq([articles[:undated]])
    end
  end

  describe "#badge_counts" do
    it "counts the unread articles of each entry" do
      state.mark_read(articles[:newest], true)

      expect(library.badge_counts(library.entries)).to eq([0, 2, 0, 2, 0])
    end

    it "counts only the unread articles that are starred for Starred" do
      state.toggle_star(articles[:newest])
      state.toggle_star(articles[:oldest])
      state.mark_read(articles[:newest], true)

      expect(library.badge_counts([entry("Starred")])).to eq([1])
    end

    it "counts zero for an entry without a badge" do
      unbadged = Library::Entry.new(key: :none, badge: false, matches: ->(_article) { true })

      expect(library.badge_counts([unbadged])).to eq([0])
    end

    it "counts the unread articles of today" do
      library.replace([Article.new(id: "4", feed: beta, date: Time.utc(2026, 3, 14, 12))])

      expect(library.badge_counts(library.entries).first).to eq(1)
    end
  end

  describe "#entries" do
    it "lists the smart feeds, then the feeds alphabetically ignoring case" do
      expect(library.entries.map(&:title)).to eq(["Today", "All Unread", "Starred", "alpha", "Beta"])
    end

    it "keys the smart feeds by symbol and the feeds by themselves" do
      expect(library.entries.map(&:key)).to eq([:today, :unread, :starred, alpha, beta])
    end

    it "says what an empty list of each entry means" do
      expect(library.entries.map(&:empty)).to eq(
        ["Nothing published today.", "All caught up.", "No starred articles.", "No articles.", "No articles."]
      )
    end

    it "marks only the smart feeds as smart" do
      expect(library.entries.map(&:smart?)).to eq([true, true, true, false, false])
    end
  end

  describe "#find" do
    it "returns the article with an ID" do
      expect(library.find("3")).to be(articles[:newest])
    end

    it "returns nothing for an unknown ID" do
      expect(library.find("missing")).to be_nil
    end

    it "returns nothing for no ID" do
      expect(library.find(nil)).to be_nil
    end
  end

  describe "#load" do
    it "reports how many feeds are done, starting before the first" do
      progress = []

      library.load(refresh: false) { |done, total| progress << [done, total] }

      expect(progress).to eq([[0, 2], [1, 2], [2, 2]])
    end

    it "hands over the articles of each feed as it is loaded" do
      loaded = []

      library.load(refresh: false, on_feed: ->(feed, feed_articles) { loaded << [feed, feed_articles] })

      expect(loaded).to contain_exactly([alpha, articles.values_at(:oldest, :undated)], [beta, [articles[:newest]]])
    end

    it "fetches several feeds at once" do
      allow(WorkerPool).to receive(:map).and_call_original

      library.load(refresh: false)

      expect(WorkerPool).to have_received(:map).with([beta, alpha], workers: FEED_FETCHERS)
    end

    it "looks for the icons of the feeds when refreshing" do
      [alpha, beta].each do |feed|
        allow(feed).to receive_messages(articles: [], refresh_icon: nil)
      end

      library.load(refresh: true)

      expect([alpha, beta]).to all(have_received(:refresh_icon))
    end

    it "does not look for icons when reading the cache" do
      allow(alpha).to receive(:refresh_icon)

      library.load(refresh: false)

      expect(alpha).not_to have_received(:refresh_icon)
    end

    it "lists the newest articles first and the undated ones last" do
      expect(library.load(refresh: false)).to eq(articles.values_at(:newest, :oldest, :undated))
    end
  end

  describe "#merge" do
    let(:fresh) { Article.new(id: "5", feed: alpha, date: Time.utc(2026, 3, 10)) }

    it "swaps in the articles of a feed, newest first among the rest" do
      library.merge(alpha, [fresh])

      expect(library.articles_for(entry("All Unread"))).to eq([fresh, articles[:newest]])
    end

    it "puts an article older than the rest last" do
      oldest = Article.new(id: "7", feed: alpha, date: Time.utc(2026, 1, 5))

      library.merge(alpha, [oldest])

      expect(library.articles_for(entry("All Unread"))).to eq([articles[:newest], oldest])
    end

    it "sorts a new article among the dated and the undated ones" do
      middle  = Article.new(id: "8", feed: beta, date: Time.utc(2026, 2, 1))
      undated = Article.new(id: "9", feed: beta, date: nil)

      library.merge(beta, [undated, middle])

      expect(library.articles_for(entry("All Unread"))).to eq([middle, articles[:oldest], undated, articles[:undated]])
    end

    it "leaves out an article older than the window" do
      stale = Article.new(id: "6", feed: alpha, date: Time.utc(2025, 1, 1))

      library.merge(alpha, [stale])

      expect(library.articles_for(entry("alpha"))).to eq([])
    end

    it "does not forget any state, since the other feeds may still be loading" do
      allow(state).to receive(:prune)

      library.merge(alpha, [fresh])

      expect(state).not_to have_received(:prune)
    end
  end

  describe "#next_unread_entry" do
    subject(:library) { described_class.new([beta, alpha, gamma], state) }

    let(:gamma) { instance_double(Feed, name: "gamma", articles: []) }

    it "returns the next feed with unread articles" do
      expect(library.next_unread_entry(library.entries, entry("alpha")).title).to eq("Beta")
    end

    it "skips a feed without unread articles and wraps around" do
      expect(library.next_unread_entry(library.entries, entry("Beta")).title).to eq("alpha")
    end

    it "starts at the first feed from a smart feed" do
      expect(library.next_unread_entry(library.entries, entry("Starred")).title).to eq("alpha")
    end

    context "when the feeds before and after have unread articles" do
      let(:gamma) do
        instance_double(Feed, name: "gamma").tap do |feed|
          allow(feed).to receive(:articles).and_return([Article.new(id: "5", feed: feed, date: Time.utc(2026, 3, 2))])
        end
      end

      it "returns the feed after it" do
        expect(library.next_unread_entry(library.entries, entry("Beta")).title).to eq("gamma")
      end
    end

    it "returns nothing when no other feed has unread articles" do
      state.mark_read(articles[:newest], true)

      expect(library.next_unread_entry(library.entries, entry("alpha"))).to be_nil
    end
  end

  describe "#replace" do
    let(:stale) { Article.new(id: "stale", feed: alpha, date: Time.utc(2025, 12, 1)) }

    it "leaves out an article older than the window" do
      library.replace([stale, articles[:newest]])

      expect(library.find("stale")).to be_nil
    end

    it "keeps an article as old as the window" do
      edge = Article.new(id: "edge", feed: alpha, date: Time.utc(2025, 12, 15))

      library.replace([edge])

      expect(library.find("edge")).to be(edge)
    end

    it "keeps an article with no date" do
      library.replace([articles[:undated]])

      expect(library.find("2")).to be(articles[:undated])
    end

    it "keeps an old article that is starred" do
      state.toggle_star(stale)
      library.replace([stale])

      expect(library.find("stale")).to be(stale)
    end

    it "tells the state which articles are still shown" do
      allow(state).to receive(:prune)
      library.replace([stale, articles[:newest]])

      expect(state).to have_received(:prune).with(Set["3"])
    end
  end

  describe "#unread_count" do
    it "counts the unread articles of an entry" do
      state.mark_read(articles[:undated], true)

      expect(library.unread_count(entry("All Unread"))).to eq(2)
    end
  end
end
