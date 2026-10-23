# frozen_string_literal: true

RSpec.describe Feed do
  subject(:feed) { described_class.new(url) }

  let(:directory) { Dir.mktmpdir }
  let(:uri)       { instance_double(URI::HTTPS, host: "www.example.com") }
  let(:url)       { "https://www.example.com/feed.xml" }
  let(:xml)       { "<rss><channel><title>Example</title><item><title>A</title></item></channel></rss>" }

  def feed_response(body)
    StringIO.new(body.dup).tap do |io|
      OpenURI::Meta.init(io)
      io.meta_add_field("etag", '"abc"')
      io.meta_add_field("last-modified", "Wed, 21 Oct 2026 10:00:00 GMT")
    end
  end

  def http_error(code, message)
    io = StringIO.new

    OpenURI::Meta.init(io)
    io.status = [code, message]
    OpenURI::HTTPError.new("#{code} #{message}", io)
  end

  before do
    stub_const("CACHE_DIR", directory)
    allow(URI).to receive(:parse).with(url).and_return(uri)
    allow(uri).to receive(:open).and_yield(feed_response(xml))
  end

  after do
    FileUtils.remove_entry(directory)
  end

  describe ".load_all" do
    let(:config) { File.join(directory, "feeds.yml") }

    before do
      stub_const("CONFIG_PATH", config)
    end

    context "with a URL, a hash and entries without a URL" do
      before do
        File.write(config, "- https://a.example/feed\n- url: https://b.example/rss\n- ''\n- name: No URL\n")
      end

      it "reads the feeds that have a URL" do
        expect(described_class.load_all.map(&:url)).to eq(%w(https://a.example/feed https://b.example/rss))
      end
    end

    context "without a file" do
      it "lists the default feeds" do
        expect(described_class.load_all.map(&:url)).to eq(YAML.safe_load(DEFAULT_FEEDS))
      end

      it "writes the default feeds to the file" do
        described_class.load_all

        expect(File.read(config)).to eq(DEFAULT_FEEDS)
      end
    end

    context "with a file that cannot be read" do
      before do
        File.write(config, "- [")
        allow(described_class).to receive(:warn)
      end

      it "lists no feeds" do
        expect(described_class.load_all).to eq([])
      end

      it "warns about the file" do
        described_class.load_all

        expect(described_class).to have_received(:warn).with(a_string_including("cannot read"))
      end
    end
  end

  describe "#articles" do
    context "without a refresh or a cache" do
      it "has no articles" do
        expect(feed.articles(refresh: false)).to eq([])
      end
    end

    context "with a refresh and no cache" do
      it "downloads the articles" do
        expect(feed.articles(refresh: true).map(&:title)).to eq(["A"])
      end

      it "caches the download" do
        feed.articles(refresh: true)

        expect(Dir[File.join(directory, "*.xml")].size).to eq(1)
      end

      it "asks for the whole feed" do
        feed.articles(refresh: true)

        expect(uri).to have_received(:open).with({ open_timeout: 10, read_timeout: 30 })
      end
    end

    context "with a fresh cache" do
      before do
        feed.articles(refresh: true)
      end

      it "does not download again" do
        feed.articles(refresh: true)

        expect(uri).to have_received(:open).once
      end

      it "reads the cache without a refresh" do
        expect(feed.articles(refresh: false).map(&:title)).to eq(["A"])
      end
    end

    context "with a stale cache" do
      before do
        feed.articles(refresh: true)
        FileUtils.touch(Dir[File.join(directory, "*.xml")], mtime: Time.now - (2 * CACHE_MAX_AGE))
      end

      it "downloads again" do
        feed.articles(refresh: true)

        expect(uri).to have_received(:open).twice
      end

      it "asks the server to send the feed only if it changed" do
        feed.articles(refresh: true)

        expect(uri).to have_received(:open).with(
          hash_including("If-None-Match" => '"abc"', "If-Modified-Since" => "Wed, 21 Oct 2026 10:00:00 GMT")
        )
      end
    end

    context "when the server says the feed has not changed" do
      include_context "with captured warnings"

      before do
        feed.articles(refresh: true)
        FileUtils.touch(Dir[File.join(directory, "*.xml")], mtime: Time.now - (2 * CACHE_MAX_AGE))
        allow(uri).to receive(:open).and_raise(http_error("304", "Not Modified"))
      end

      it "returns the articles that are cached" do
        expect(feed.articles(refresh: true).map(&:title)).to eq(["A"])
      end

      it "counts the cached copy as new, so that it is not asked for again" do
        2.times { feed.articles(refresh: true) }

        expect(uri).to have_received(:open).twice
      end

      it "does not warn" do
        feed.articles(refresh: true)

        expect(Warning).not_to have_received(:warn)
      end
    end

    context "when the server answers with an error" do
      include_context "with captured warnings"

      before do
        feed.articles(refresh: true)
        FileUtils.touch(Dir[File.join(directory, "*.xml")], mtime: Time.now - (2 * CACHE_MAX_AGE))
        allow(uri).to receive(:open).and_raise(http_error("500", "Internal Server Error"))
      end

      it "falls back to the cache" do
        expect(feed.articles(refresh: true).map(&:title)).to eq(["A"])
      end

      it "warns about the status" do
        feed.articles(refresh: true)

        expect(Warning).to have_received(:warn).with(a_string_including("500"), any_args)
      end
    end

    context "when the download fails" do
      include_context "with captured warnings"

      before do
        allow(uri).to receive(:open).and_raise(StandardError.new("offline"))
      end

      it "has no articles without a cache" do
        expect(feed.articles(refresh: true)).to eq([])
      end

      it "warns about the failure" do
        feed.articles(refresh: true)

        expect(Warning).to have_received(:warn).with(a_string_including("offline"), any_args)
      end
    end

    context "when the download fails with a stale cache" do
      include_context "with captured warnings"

      before do
        feed.articles(refresh: true)
        FileUtils.touch(Dir[File.join(directory, "*.xml")], mtime: Time.now - (2 * CACHE_MAX_AGE))
        allow(uri).to receive(:open).and_raise(StandardError.new("offline"))
      end

      it "falls back to the cache" do
        expect(feed.articles(refresh: true).map(&:title)).to eq(["A"])
      end
    end
  end

  describe "#refresh_icon" do
    before do
      allow(feed.icon).to receive(:refresh)
    end

    it "looks for the icon on the home page" do
      feed.home_page = "https://example.com/blog/"
      feed.image_url = "https://example.com/logo.png"
      feed.refresh_icon

      expect(feed.icon).to have_received(:refresh)
        .with(home_page: "https://example.com/blog/", image_url: "https://example.com/logo.png")
    end

    it "looks at the root of the site without a home page" do
      feed.refresh_icon

      expect(feed.icon).to have_received(:refresh).with(home_page: "https://www.example.com/", image_url: nil)
    end

    context "when the URL of the feed cannot be parsed" do
      let(:url) { "not a url" }

      it "looks for nothing" do
        feed.refresh_icon

        expect(feed.icon).not_to have_received(:refresh)
      end
    end
  end

  describe "#name" do
    it "is the domain without www until the feed gives a title" do
      expect(feed.name).to eq("example.com")
    end

    it "is the feed's own title once it is known" do
      feed.title = "Example"

      expect(feed.name).to eq("Example")
    end

    context "with a URL that has no host" do
      let(:uri) { instance_double(URI::Generic, host: nil) }
      let(:url) { "feed.xml" }

      it "is the whole URL" do
        expect(feed.name).to eq("feed.xml")
      end
    end

    context "with a URL that cannot be parsed" do
      let(:url) { "not a url" }

      before do
        allow(URI).to receive(:parse).with(url).and_raise(URI::InvalidURIError)
      end

      it "is the whole URL" do
        expect(feed.name).to eq("not a url")
      end
    end
  end

  describe "#url" do
    it "is the URL the feed was created with" do
      expect(feed.url).to eq(url)
    end
  end
end
