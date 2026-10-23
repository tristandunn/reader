# frozen_string_literal: true

RSpec.describe ImageDownloader do
  subject(:downloader) { described_class.new(workers: workers) }

  let(:results) { Queue.new }
  let(:workers) { 1 }

  def fetch(url, wanted: true)
    downloader.fetch(url, still_wanted: -> { wanted }) { |data| results << [url, data] }
  end

  before do
    allow(ImageStore).to receive(:fetch) { |url| "bytes of #{url}" }
  end

  describe "#fetch" do
    it "passes the bytes of the image to the block" do
      fetch("a.png")

      expect(results.pop(timeout: 2)).to eq(["a.png", "bytes of a.png"])
    end

    it "skips an image that is no longer wanted" do
      fetch("stale.png", wanted: false)
      fetch("fresh.png")
      results.pop(timeout: 2)

      expect(ImageStore).not_to have_received(:fetch).with("stale.png")
    end

    context "with a block that raises" do
      include_context "with captured warnings"

      it "keeps downloading the images after it" do
        downloader.fetch("bad.png", still_wanted: -> { true }) { |_data| raise "broken" }
        fetch("good.png")

        expect(results.pop(timeout: 2)).to eq(["good.png", "bytes of good.png"])
      end

      it "warns about the failure" do
        downloader.fetch("bad.png", still_wanted: -> { true }) { |_data| raise "broken" }
        fetch("good.png")
        results.pop(timeout: 2)

        expect(Warning).to have_received(:warn).with(a_string_including("broken"), any_args)
      end
    end

    context "with more images than workers" do
      let(:gate)    { Queue.new }
      let(:started) { Queue.new }
      let(:workers) { 2 }

      before do
        allow(ImageStore).to receive(:fetch) do |url|
          started << url
          gate.pop(timeout: 5)
        end
        4.times { |index| fetch("#{index}.png") }
        2.times { started.pop(timeout: 2) }
      end

      after do
        4.times { gate << "bytes" }
        4.times { results.pop(timeout: 2) }
      end

      it "downloads no more than the workers at once" do
        expect(started.size).to eq(0)
      end
    end
  end
end
