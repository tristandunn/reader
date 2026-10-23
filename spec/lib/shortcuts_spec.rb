# frozen_string_literal: true

RSpec.describe Shortcuts do
  describe ".action_for" do
    let(:command_keys) { %i(ctrl alt super meta) }

    {
      "space"    => :scroll_or_next_unread,
      "n"        => :next_unread,
      "plus"     => :next_unread,
      "KP_Add"   => :next_unread,
      "r"        => :toggle_read,
      "u"        => :toggle_read,
      "k"        => :mark_all_read,
      "o"        => :mark_older_read,
      "l"        => :mark_all_read_and_next_unread,
      "m"        => :mark_unread_and_next_unread,
      "s"        => :toggle_star,
      "b"        => :open_in_browser,
      "Return"   => :open_in_browser,
      "KP_Enter" => :open_in_browser,
      "a"        => :previous_feed,
      "z"        => :next_feed,
      "Left"     => :focus_sidebar,
      "Right"    => :focus_article_list
    }.each do |key, action|
      it "maps #{key} to #{action}" do
        expect(described_class.action_for(key, [])).to eq(action)
      end

      it "ignores #{key} while a command key without its own shortcut is held" do
        unbound = command_keys.reject { |held| described_class::COMMAND_ACTIONS.key?([key, [held]]) }

        expect(unbound.map { |held| described_class.action_for(key, [held]) }).to all(be_nil)
      end
    end

    it "maps Ctrl+R to reload" do
      expect(described_class.action_for("r", %i(ctrl))).to eq(:reload)
    end

    it "maps Super+R to reload" do
      expect(described_class.action_for("r", %i(super))).to eq(:reload)
    end

    it "does not reload on Alt+R" do
      expect(described_class.action_for("r", %i(alt))).to be_nil
    end

    it "does not reload when other modifiers are held as well" do
      expect(described_class.action_for("r", %i(ctrl alt))).to be_nil
    end

    it "ignores a key that has no shortcut" do
      expect(described_class.action_for("x", [])).to be_nil
    end

    it "ignores a key that has no name" do
      expect(described_class.action_for(nil, [])).to be_nil
    end
  end
end
