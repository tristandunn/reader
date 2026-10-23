# frozen_string_literal: true

RSpec.describe Column do
  describe ".margin_end" do
    it "is zero in a pane narrower than the widest column" do
      expect(described_class.margin_end(600)).to eq(0)
    end

    it "is zero in a pane as wide as the widest column" do
      expect(described_class.margin_end(READER_MAX_WIDTH)).to eq(0)
    end

    it "takes up the width beyond the widest column" do
      expect(described_class.margin_end(READER_MAX_WIDTH + 150)).to eq(150)
    end
  end

  describe ".text_width" do
    it "is the pane width less the padding in a narrow pane" do
      expect(described_class.text_width(600)).to eq(600 - COLUMN_PADDING)
    end

    it "is capped by the widest column in a wide pane" do
      expect(described_class.text_width(READER_MAX_WIDTH + 400)).to eq(READER_MAX_WIDTH - COLUMN_PADDING)
    end
  end
end
