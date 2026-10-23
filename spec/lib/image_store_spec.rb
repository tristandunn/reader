# frozen_string_literal: true

RSpec.describe ImageStore do
  let(:directory) { Dir.mktmpdir }
  let(:response)  { image_response("bytes") }
  let(:uri)       { instance_double(URI::HTTPS) }
  let(:url)       { "https://example.com/a.png" }

  def image_response(body, type = "image/png")
    StringIO.new(body.dup).tap do |io|
      OpenURI::Meta.init(io)
      io.meta_add_field("content-type", type)
    end
  end

  def keep(name, content, age)
    FileUtils.mkdir_p(IMAGE_DIR)
    path = File.join(IMAGE_DIR, name)

    File.binwrite(path, content)
    FileUtils.touch(path, mtime: Time.now - age)
    path
  end

  before do
    stub_const("IMAGE_DIR", File.join(directory, "images"))
    allow(URI).to receive(:parse).with(url).and_return(uri)
    allow(uri).to receive(:open).and_yield(response)
  end

  after do
    FileUtils.remove_entry(directory)
  end

  describe ".fetch" do
    context "when the image is not kept yet" do
      it "downloads it" do
        expect(described_class.fetch(url)).to eq("bytes".b)
      end

      it "keeps it on disk" do
        described_class.fetch(url)

        expect(Dir[File.join(IMAGE_DIR, "*")].map { |path| File.binread(path) }).to eq(["bytes".b])
      end
    end

    context "when the image is kept" do
      let(:path) { keep(Digest::SHA256.hexdigest(url)[0, 24], "kept", 3600) }

      before do
        path
      end

      it "reads it from disk without downloading" do
        described_class.fetch(url)

        expect(uri).not_to have_received(:open)
      end

      it "returns what is kept" do
        expect(described_class.fetch(url)).to eq("kept")
      end

      it "marks it as recently used" do
        described_class.fetch(url)

        expect(File.mtime(path)).to be > (Time.now - 60)
      end
    end

    context "when the response is not an image" do
      include_context "with captured warnings"

      let(:response) { image_response("<html>", "text/html") }

      it "returns nil" do
        expect(described_class.fetch(url)).to be_nil
      end

      it "does not keep it" do
        described_class.fetch(url)

        expect(Dir[File.join(IMAGE_DIR, "*")]).to be_empty
      end

      it "warns about the content type" do
        described_class.fetch(url)

        expect(Warning).to have_received(:warn).with(a_string_including("text/html"), any_args)
      end
    end

    context "when the image is exactly as large as the limit" do
      let(:response) { image_response("1234") }

      before do
        stub_const("IMAGE_MAX_BYTES", 4)
      end

      it "downloads it" do
        expect(described_class.fetch(url)).to eq("1234")
      end
    end

    context "when the image is larger than the limit" do
      include_context "with captured warnings"

      let(:response) { image_response("12345") }

      before do
        stub_const("IMAGE_MAX_BYTES", 4)
      end

      it "returns nil" do
        expect(described_class.fetch(url)).to be_nil
      end

      it "does not keep the truncated image" do
        described_class.fetch(url)

        expect(Dir[File.join(IMAGE_DIR, "*")]).to be_empty
      end
    end

    context "when the images kept are larger than the cache allows" do
      before do
        stub_const("IMAGE_CACHE_MAX_BYTES", 10)
        keep("oldest", "old1", 7200)
        keep("newer", "new2", 3600)
      end

      it "removes the one used least recently" do
        described_class.fetch(url)

        expect(Dir[File.join(IMAGE_DIR, "*")].map { |path| File.binread(path) }.sort).to eq(["bytes".b, "new2".b])
      end
    end

    context "when the download fails" do
      include_context "with captured warnings"

      before do
        allow(uri).to receive(:open).and_raise(StandardError.new("offline"))
      end

      it "returns nil" do
        expect(described_class.fetch(url)).to be_nil
      end

      it "warns about the failure" do
        described_class.fetch(url)

        expect(Warning).to have_received(:warn).with(a_string_including("offline"), any_args)
      end
    end
  end
end
