# frozen_string_literal: true

RSpec.describe FeedIcon do
  subject(:icon) { described_class.new("https://example.com/feed") }

  let(:directory) { Dir.mktmpdir }
  let(:home)      { instance_double(URI::HTTPS) }
  let(:home_page) { "https://example.com/" }
  let(:html)      { '<link rel="apple-touch-icon" href="/touch.png">' }

  def keep(content, age)
    path = File.join(ICON_DIR, Digest::SHA256.hexdigest("https://example.com/feed")[0, 16])

    FileUtils.mkdir_p(ICON_DIR)
    File.binwrite(path, content)
    FileUtils.touch(path, mtime: Time.now - age)
  end

  before do
    stub_const("ICON_DIR", File.join(directory, "icons"))
    allow(URI).to receive(:parse).with(home_page).and_return(home)
    allow(home).to receive(:open).and_yield(StringIO.new(html))
    allow(ImageStore).to receive(:read).and_raise("not an image")
    allow(ImageStore).to receive(:read).with("https://example.com/touch.png").and_return("touch".b)
  end

  after do
    FileUtils.remove_entry(directory)
  end

  describe "#read" do
    it "returns nothing before the icon is fetched" do
      expect(icon.read).to be_nil
    end

    it "returns nothing when no icon was found" do
      keep("", 0)

      expect(icon.read).to be_nil
    end

    it "returns the kept icon" do
      keep("png", 0)

      expect(icon.read).to eq("png".b)
    end
  end

  describe "#refresh" do
    it "keeps the first icon of the home page that downloads" do
      icon.refresh(home_page: home_page, image_url: nil)

      expect(icon.read).to eq("touch".b)
    end

    it "moves the icon into place from a file beside it" do
      allow(File).to receive(:rename).and_call_original

      icon.refresh(home_page: home_page, image_url: nil)

      expect(File).to have_received(:rename).with(end_with(".tmp"), anything)
    end

    it "skips an icon that does not download" do
      page = '<link rel="apple-touch-icon" href="/missing.png"><link rel="icon" href="/touch.png">'

      allow(home).to receive(:open).and_yield(StringIO.new(page))

      icon.refresh(home_page: home_page, image_url: nil)

      expect(icon.read).to eq("touch".b)
    end

    it "falls back to the image of the feed" do
      allow(ImageStore).to receive(:read).with("https://example.com/logo.png").and_return("logo".b)
      allow(home).to receive(:open).and_yield(StringIO.new(""))

      icon.refresh(home_page: home_page, image_url: "https://example.com/logo.png")

      expect(icon.read).to eq("logo".b)
    end

    it "falls back to the favicon at the root of the site" do
      allow(ImageStore).to receive(:read).with("https://example.com/favicon.ico").and_return("ico".b)
      allow(home).to receive(:open).and_yield(StringIO.new(""))

      icon.refresh(home_page: home_page, image_url: nil)

      expect(icon.read).to eq("ico".b)
    end

    it "prefers the image of the feed to the favicon" do
      allow(ImageStore).to receive(:read).with("https://example.com/favicon.ico").and_return("ico".b)
      allow(ImageStore).to receive(:read).with("https://example.com/logo.png").and_return("logo".b)
      allow(home).to receive(:open).and_yield(StringIO.new(""))

      icon.refresh(home_page: home_page, image_url: "https://example.com/logo.png")

      expect(icon.read).to eq("logo".b)
    end

    it "remembers that there is no icon, so it is not looked for again" do
      allow(home).to receive(:open).and_raise(IOError, "offline")

      icon.refresh(home_page: home_page, image_url: nil)
      icon.refresh(home_page: home_page, image_url: nil)

      expect(home).to have_received(:open).once
    end

    it "does not look again while the icon is fresh" do
      keep("png", 0)
      icon.refresh(home_page: home_page, image_url: nil)

      expect(home).not_to have_received(:open)
    end

    it "looks again once the icon is old" do
      keep("png", ICON_MAX_AGE + 1)
      icon.refresh(home_page: home_page, image_url: nil)

      expect(icon.read).to eq("touch".b)
    end

    context "when looking for the icon fails" do
      include_context "with captured warnings"

      before do
        allow(IconLinks).to receive(:candidates).and_raise(Nokogiri::XML::XPath::SyntaxError, "Invalid expression")
      end

      it "does not stop the refresh" do
        expect { icon.refresh(home_page: home_page, image_url: nil) }.not_to raise_error
      end

      it "warns about the failure" do
        icon.refresh(home_page: home_page, image_url: nil)

        expect(Warning).to have_received(:warn).with(a_string_including("Invalid expression"), any_args)
      end
    end

    it "reads no more of the home page than the limit" do
      page = StringIO.new(html)

      allow(home).to receive(:open).and_yield(page)
      allow(page).to receive(:read).and_call_original

      icon.refresh(home_page: home_page, image_url: nil)

      expect(page).to have_received(:read).with(HOME_PAGE_MAX_BYTES)
    end
  end
end
