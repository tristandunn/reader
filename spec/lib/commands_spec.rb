# frozen_string_literal: true

RSpec.describe Commands do
  subject(:commands) { described_class.new(library, actions, window) }

  let(:actions)  { double(mark_all_read: nil, mark_below_read: nil, mark_read: nil) }
  let(:articles) { Array.new(3) { |index| Article.new(id: index.to_s) } }
  let(:library)  do
    instance_double(Library, entries:           [Library::Entry.new(key: :unread), Library::Entry.new(key: :feed)],
                             next_unread_entry: nil)
  end
  let(:state)    { ReadState.new("missing.yml") }
  let(:window)   do
    double(
      entry:   library.entries.first,
      list:    double(focus: nil, select: nil, timeline: Timeline.new(articles, state)),
      reader:  double(article: articles[0], more_below?: false, scroll_page: nil),
      reload:  nil,
      sidebar: double(focus: nil, select: nil, select_relative: nil)
    )
  end

  it "has a command for every shortcut" do
    names = Shortcuts::ACTIONS.values + Shortcuts::COMMAND_ACTIONS.values

    expect(names.reject { |name| commands.respond_to?(name) }).to eq([])
  end

  describe "#focus_article_list" do
    it "moves the focus to the article list" do
      commands.focus_article_list

      expect(window.list).to have_received(:focus)
    end
  end

  describe "#focus_sidebar" do
    it "moves the focus to the sidebar" do
      commands.focus_sidebar

      expect(window.sidebar).to have_received(:focus)
    end
  end

  describe "#mark_all_read" do
    it "marks every listed article as read" do
      commands.mark_all_read

      expect(actions).to have_received(:mark_all_read).with(articles)
    end
  end

  describe "#mark_all_read_and_next_unread" do
    it "marks every listed article as read, then moves on" do
      allow(window.list).to receive(:timeline).and_return(Timeline.new(articles, state), Timeline.new([], state))

      commands.mark_all_read_and_next_unread

      expect(library).to have_received(:next_unread_entry)
    end
  end

  describe "#mark_older_read" do
    it "marks the articles below the open one as read" do
      commands.mark_older_read

      expect(actions).to have_received(:mark_below_read).with(articles[0])
    end
  end

  describe "#mark_unread_and_next_unread" do
    it "marks the open article as unread" do
      commands.mark_unread_and_next_unread

      expect(actions).to have_received(:mark_read).with(articles[0], false)
    end

    it "moves on to the next unread article" do
      commands.mark_unread_and_next_unread

      expect(window.list).to have_received(:select).with(articles[1])
    end

    it "only moves on without an open article" do
      allow(window.reader).to receive(:article).and_return(nil)

      commands.mark_unread_and_next_unread

      expect(actions).not_to have_received(:mark_read)
    end
  end

  describe "#next_feed" do
    it "selects the next entry of the sidebar" do
      commands.next_feed

      expect(window.sidebar).to have_received(:select_relative).with(1)
    end
  end

  describe "#next_unread" do
    it "selects the next unread article in the list" do
      state.mark_read(articles[1], true)

      commands.next_unread

      expect(window.list).to have_received(:select).with(articles[2])
    end

    context "when the list has no other unread article" do
      before do
        articles.drop(1).each { |article| state.mark_read(article, true) }
        allow(library).to receive(:next_unread_entry).with(library.entries, window.entry)
                                                     .and_return(library.entries.last)
      end

      it "selects the next feed with unread articles" do
        commands.next_unread

        expect(window.sidebar).to have_received(:select).with(:feed)
      end

      it "opens the first unread article of that feed" do
        allow(window.sidebar).to receive(:select) do
          allow(window.list).to receive(:timeline).and_return(Timeline.new([Article.new(id: "new")], state))
        end

        commands.next_unread

        expect(window.list).to have_received(:select).with(have_attributes(id: "new"))
      end
    end

    context "when no feed has unread articles" do
      before do
        articles.drop(1).each { |article| state.mark_read(article, true) }
      end

      it "stays where it is" do
        commands.next_unread

        expect(window.sidebar).not_to have_received(:select)
      end
    end
  end

  describe "#open_in_browser" do
    it "opens the open article" do
      allow(actions).to receive(:open_in_browser)

      commands.open_in_browser

      expect(actions).to have_received(:open_in_browser).with(articles[0])
    end
  end

  describe "#previous_feed" do
    it "selects the previous entry of the sidebar" do
      commands.previous_feed

      expect(window.sidebar).to have_received(:select_relative).with(-1)
    end
  end

  describe "#reload" do
    it "starts a refresh" do
      commands.reload

      expect(window).to have_received(:reload)
    end
  end

  describe "#scroll_or_next_unread" do
    it "scrolls the article when there is more of it" do
      allow(window.reader).to receive(:more_below?).and_return(true)

      commands.scroll_or_next_unread

      expect(window.reader).to have_received(:scroll_page)
    end

    it "does not move on while there is more of the article" do
      allow(window.reader).to receive(:more_below?).and_return(true)

      commands.scroll_or_next_unread

      expect(window.list).not_to have_received(:select)
    end

    it "moves on to the next unread article at the end of the article" do
      commands.scroll_or_next_unread

      expect(window.list).to have_received(:select).with(articles[1])
    end
  end

  describe "#toggle_read" do
    it "toggles whether the open article is read" do
      allow(actions).to receive(:toggle_read)

      commands.toggle_read

      expect(actions).to have_received(:toggle_read).with(articles[0])
    end
  end

  describe "#toggle_star" do
    it "toggles whether the open article is starred" do
      allow(actions).to receive(:toggle_star)

      commands.toggle_star

      expect(actions).to have_received(:toggle_star).with(articles[0])
    end
  end
end
