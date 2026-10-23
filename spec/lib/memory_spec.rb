# frozen_string_literal: true

RSpec.describe Memory do
  describe ".trim" do
    before do
      allow(GC).to receive(:start)
    end

    it "collects garbage before returning memory" do
      described_class.trim

      expect(GC).to have_received(:start)
    end

    it "returns memory to the operating system" do
      expect(described_class::TRIM.call(0)).to be_between(0, 1)
    end
  end
end
