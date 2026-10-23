# frozen_string_literal: true

RSpec.describe Monogram do
  describe ".letter" do
    it "is the first letter of the name, capitalized" do
      expect(described_class.letter("daring Fireball")).to eq("D")
    end

    it "skips punctuation" do
      expect(described_class.letter("“Quoted”")).to eq("Q")
    end

    it "is a bullet for a name without letters or digits" do
      expect(described_class.letter("…")).to eq("•")
    end
  end

  describe ".tint" do
    it "is a CSS class from the palette" do
      expect(described_class.tint("Ruby Weekly")).to match(/\Atint-[0-#{Monogram::TINTS - 1}]\z/o)
    end

    it "comes from the name, so it stays the same between runs" do
      expect(described_class.tint("Ruby Weekly")).to eq("tint-3")
    end

    it "differs between names" do
      expect(%w(alpha beta gamma delta).map { |name| described_class.tint(name) }.uniq.size).to be > 1
    end
  end
end
