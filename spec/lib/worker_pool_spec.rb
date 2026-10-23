# frozen_string_literal: true

RSpec.describe WorkerPool do
  describe ".map" do
    it "returns the results in the order of the items" do
      result = described_class.map([3, 1, 2], workers: 3) do |item|
        sleep(item / 1000.0)
        item * 10
      end

      expect(result).to eq([30, 10, 20])
    end

    it "runs the items at the same time" do
      lock    = Mutex.new
      running = 0
      peak    = 0

      described_class.map([1, 2, 3], workers: 2) do |_item|
        lock.synchronize { peak = [peak, running += 1].max }
        sleep(0.02)
        lock.synchronize { running -= 1 }
      end

      expect(peak).to eq(2)
    end

    it "starts no more threads than there are items" do
      allow(Thread).to receive(:new).and_call_original

      described_class.map([1], workers: 4) { |item| item }

      expect(Thread).to have_received(:new).once
    end

    it "returns nothing for no items" do
      expect(described_class.map([], workers: 2) { |item| item }).to eq([])
    end
  end
end
