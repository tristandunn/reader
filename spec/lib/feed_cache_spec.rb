# frozen_string_literal: true

RSpec.describe FeedCache do
  subject(:cache) { described_class.new("https://example.com/feed.xml") }

  let(:directory) { Dir.mktmpdir }
  let(:meta)      { { "etag" => '"abc"', "last-modified" => "Wed, 21 Oct 2026 10:00:00 GMT" } }

  before do
    stub_const("CACHE_DIR", File.join(directory, "cache"))
  end

  after do
    FileUtils.remove_entry(directory)
  end

  describe "#conditional_headers" do
    it "is empty before anything is cached" do
      expect(cache.conditional_headers).to eq({})
    end

    it "asks for the feed only if it changed, once a response has been cached" do
      cache.write("<rss/>", meta)

      expect(cache.conditional_headers).to eq("If-None-Match" => '"abc"', "If-Modified-Since" => meta["last-modified"])
    end

    it "leaves off the -gzip that some servers add to the ETag of a compressed response" do
      cache.write("<rss/>", "etag" => '"4ebe-gzip"')

      expect(cache.conditional_headers).to eq("If-None-Match" => '"4ebe"')
    end

    it "uses what the server gave when it gave only one of the two" do
      cache.write("<rss/>", "etag" => '"abc"')

      expect(cache.conditional_headers).to eq("If-None-Match" => '"abc"')
    end

    it "is empty when the server gave neither" do
      cache.write("<rss/>", {})

      expect(cache.conditional_headers).to eq({})
    end

    it "forgets what an earlier response said" do
      cache.write("<rss/>", meta)
      cache.write("<rss/>", {})

      expect(cache.conditional_headers).to eq({})
    end

    it "is empty when the cached copy is gone" do
      cache.write("<rss/>", meta)
      FileUtils.rm_f(Dir[File.join(CACHE_DIR, "*.xml")])

      expect(cache.conditional_headers).to eq({})
    end

    it "is empty when what was saved cannot be read" do
      cache.write("<rss/>", meta)
      File.write(Dir[File.join(CACHE_DIR, "*.yml")].first, "- [")

      expect(cache.conditional_headers).to eq({})
    end
  end

  describe "#read" do
    it "is nil before anything is cached" do
      expect(cache.read).to be_nil
    end

    it "is what was cached" do
      cache.write("<rss/>", meta)

      expect(cache.read).to eq("<rss/>")
    end
  end

  describe "#stale?" do
    it "is true before anything is cached" do
      expect(cache.stale?).to be(true)
    end

    it "is false just after caching" do
      cache.write("<rss/>", meta)

      expect(cache.stale?).to be(false)
    end

    it "is true once the copy is older than the maximum age" do
      cache.write("<rss/>", meta)
      FileUtils.touch(Dir[File.join(CACHE_DIR, "*.xml")], mtime: Time.now - (2 * CACHE_MAX_AGE))

      expect(cache.stale?).to be(true)
    end
  end

  describe "#touch" do
    it "makes an old copy fresh again" do
      cache.write("<rss/>", meta)
      FileUtils.touch(Dir[File.join(CACHE_DIR, "*.xml")], mtime: Time.now - (2 * CACHE_MAX_AGE))

      expect { cache.touch }.to change(cache, :stale?).from(true).to(false)
    end
  end
end
