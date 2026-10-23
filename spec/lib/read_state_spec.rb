# frozen_string_literal: true

RSpec.describe ReadState do
  subject(:state) { described_class.new(path) }

  let(:article)   { Article.new(id: "feed:1") }
  let(:directory) { Dir.mktmpdir }
  let(:path)      { File.join(directory, "state.yml") }

  after do
    FileUtils.remove_entry(directory)
  end

  describe "#mark_read" do
    it "marks an article as read" do
      expect { state.mark_read(article, true) }.to change { state.read?(article) }.from(false).to(true)
    end

    it "marks an article as unread" do
      state.mark_read(article, true)

      expect { state.mark_read(article, false) }.to change { state.read?(article) }.from(true).to(false)
    end
  end

  describe "#prune" do
    let(:read_on) { Date.new(2026, 1, 1) }

    before do
      allow(Time).to receive(:now).and_return(read_on.to_time)
      state.mark_read(article, true)
    end

    context "when the article was read longer ago than the window" do
      before do
        allow(Time).to receive(:now).and_return((read_on + ARTICLE_MAX_AGE_DAYS + 1).to_time)
      end

      it "forgets it when it is no longer shown" do
        expect { state.prune(Set.new) }.to change { state.read?(article) }.from(true).to(false)
      end

      it "keeps it while it is still shown" do
        expect { state.prune(Set["feed:1"]) }.not_to(change { state.read?(article) })
      end

      it "saves what is left" do
        state.save
        state.prune(Set.new)

        expect(described_class.new(path).read?(article)).to be(false)
      end

      it "keeps a starred article" do
        state.toggle_star(article)
        state.prune(Set.new)

        expect(state.starred?(article)).to be(true)
      end
    end

    context "when the article was read exactly as long ago as the window" do
      before do
        allow(Time).to receive(:now).and_return((read_on + ARTICLE_MAX_AGE_DAYS).to_time)
      end

      it "keeps it" do
        expect { state.prune(Set.new) }.not_to(change { state.read?(article) })
      end

      it "writes nothing, since nothing was forgotten" do
        state.prune(Set.new)

        expect(File.exist?(path)).to be(false)
      end
    end
  end

  describe "#save" do
    context "when the file can be written" do
      let(:reloaded) { described_class.new(path) }

      before do
        state.mark_read(article, true)
        state.toggle_star(article)
        state.save
      end

      it "keeps what was read" do
        expect(reloaded.read?(article)).to be(true)
      end

      it "keeps what was starred" do
        expect(reloaded.starred?(article)).to be(true)
      end

      it "leaves no temporary file behind" do
        expect(Dir.children(directory)).to eq(["state.yml"])
      end
    end

    context "when writing is cut short" do
      include_context "with captured warnings"

      before do
        state.save
        allow(File).to receive(:write).and_call_original
        allow(File).to receive(:write).with("#{path}.tmp", anything).and_raise(IOError, "disk full")
        state.mark_read(article, true)
      end

      it "keeps the file as it was" do
        expect { state.save }.not_to(change { File.read(path) })
      end
    end

    context "when the file cannot be written" do
      let(:path) { File.join(directory, "missing", "state.yml") }

      it "warns about the file" do
        expect { state.save }.to output(/cannot write/).to_stderr
      end
    end
  end

  describe "#starred?" do
    it "is false for a new article" do
      expect(state.starred?(article)).to be(false)
    end
  end

  describe "#toggle_star" do
    it "stars an article" do
      expect { state.toggle_star(article) }.to change { state.starred?(article) }.from(false).to(true)
    end

    it "unstars a starred article" do
      state.toggle_star(article)

      expect { state.toggle_star(article) }.to change { state.starred?(article) }.from(true).to(false)
    end
  end

  context "with a file that cannot be read" do
    before do
      File.write(path, "- [")
    end

    it "warns about the file" do
      expect { state }.to output(/cannot read/).to_stderr
    end
  end

  context "with a file from before articles were dated" do
    before do
      allow(Time).to receive(:now).and_return(Date.new(2026, 1, 1).to_time)
      File.write(path, YAML.dump("read" => ["feed:1"], "starred" => []))
    end

    it "counts the articles as read when it is first read" do
      state.prune(Set.new)
      allow(Time).to receive(:now).and_return((Date.new(2026, 1, 1) + ARTICLE_MAX_AGE_DAYS + 1).to_time)

      expect { state.prune(Set.new) }.to change { state.read?(article) }.from(true).to(false)
    end
  end

  context "with a file that dates each article" do
    before do
      allow(Time).to receive(:now).and_return(Date.new(2026, 6, 1).to_time)
      File.write(path, YAML.dump("read" => { "feed:1" => "2026-01-01" }, "starred" => []))
    end

    it "forgets an article read longer ago than the window" do
      expect { state.prune(Set.new) }.to change { state.read?(article) }.from(true).to(false)
    end
  end

  context "with a file that lists articles" do
    before do
      File.write(path, YAML.dump("read" => ["feed:1"], "starred" => []))
    end

    it "remembers what was read" do
      expect(state.read?(article)).to be(true)
    end
  end
end
