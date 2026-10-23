# frozen_string_literal: true

class ArticleList
  include Ui

  attr_reader :timeline, :widget

  # Build the list.
  #
  # The list only builds rows for the articles in view, and fills them again
  # as it scrolls, so a smart feed of thousands of articles opens as quickly as
  # a feed of ten. Its items are positions rather than articles, so a new list
  # of articles keeps the rows already built and only fills them again.
  #
  # @param state [ReadState] What decides how the rows are styled.
  # @param menu [#call] Called with an article to get its right-click menu, which does not select the row.
  # @param on_activate [#call] Called with the article of a row that is double-clicked.
  # @param on_select [#call] Called with the article of a row that gets selected.
  def initialize(state, menu:, on_activate:, on_select:)
    @state     = state
    @on_select = on_select
    @timeline  = Timeline.new([], state)
    @quiet     = false
    @row_menu  = RowMenu.new(menu: menu)
    @rows      = ArticleRows.new(state, menu: @row_menu, timeline: -> { @timeline })
    @model     = Gtk::StringList.new([])
    @selection = build_selection
    @widget    = build_stack(on_activate)
  end

  # Move the keyboard focus to the list, onto the selected article.
  #
  # @return [void]
  def focus
    if @model.n_items.positive?
      @view.scroll_to(selected_position || 0, :focus, nil)
    end
  end

  # Replace the rows with a refreshed list of articles, keeping one selected.
  #
  # The selection is not announced, because the article it holds is already
  # being shown. When the same articles are listed, the rows are only filled
  # again, so the list keeps its place.
  #
  # @param articles [Array<Article>] The articles to list.
  # @param selected_id [String, nil] The ID of the article to keep selected.
  # @return [void]
  def refresh(articles, selected_id)
    if articles.map(&:id) == @timeline.articles.map(&:id)
      @timeline = Timeline.new(articles, @state)
      @rows.rebind
    else
      show(articles, @empty.text)
      quietly { select_position(@timeline.index(@timeline.find(selected_id)), focus: false) }
    end
  end

  # Update the read and starred styling of a row to match the state.
  #
  # @param article [Article] The article whose row to update.
  # @return [void]
  def restyle(article)
    @rows.restyle(article)
  end

  # Update the styling of every row in view.
  #
  # @return [void]
  def restyle_all
    @rows.restyle_all
  end

  # Select an article and move the focus to it, which announces it.
  #
  # @param article [Article, nil] The article to select, which selects nothing when absent.
  # @return [void]
  def select(article)
    select_position(@timeline.index(article), focus: true)
  end

  # Replace the rows with one per article, with nothing selected.
  #
  # @param articles [Array<Article>] The articles to list.
  # @param empty_text [String] What to say when there are no articles.
  # @return [void]
  def show(articles, empty_text)
    @row_menu.close
    @timeline   = Timeline.new(articles, @state)
    @empty.text = empty_text
    quietly { replace_items(articles) }
    @widget.visible_child_name = articles.empty? ? "empty" : "list"
  end

  private

  # Announce the article of the selected row, unless it is being selected
  # quietly.
  #
  # @return [void]
  def announce
    position = selected_position

    if announce?(position)
      @on_select.call(@timeline.articles[position])
    end
  end

  # Return whether selecting a row should be announced.
  #
  # @param position [Integer, nil] The position of the selected row.
  # @return [Boolean] Whether a row is selected and it is not being selected quietly.
  def announce?(position)
    !position.nil? && !@quiet
  end

  # Build what tracks the selected row, announcing each new selection.
  #
  # @return [Gtk::SingleSelection] The selection.
  def build_selection
    selection = build(Gtk::SingleSelection, @model, autoselect: false, can_unselect: true)

    selection.signal_connect("selection-changed") { announce }
    selection
  end

  # Build the stack that switches between the list and the empty state.
  #
  # @param on_activate [#call] Called with the article of a row that is double-clicked.
  # @return [Gtk::Stack] The stack.
  def build_stack(on_activate)
    @view  = build_view(on_activate)
    @empty = label("", "empty-state", xalign: 0.5)
    stack  = build(Gtk::Stack, vexpand: true)

    stack.add_named(build(Gtk::ScrolledWindow, child: @view, hscrollbar_policy: :never, vexpand: true), "list")
    stack.add_named(empty_state("mail-read-symbolic", @empty), "empty")
    stack
  end

  # Build the list itself, which opens a double-clicked article in the browser.
  #
  # @param on_activate [#call] Called with the article of a row that is double-clicked.
  # @return [Gtk::ListView] The list.
  def build_view(on_activate)
    view = build(Gtk::ListView, @selection, @rows.factory, css: "articles")

    view.signal_connect("activate") { |_view, position| on_activate.call(@timeline.articles[position]) }
    view
  end

  # Run a block without announcing the selections it makes.
  #
  # @yield What to run.
  # @return [void]
  def quietly
    @quiet = true
    yield
  ensure
    @quiet = false
  end

  # Swap in the rows for a new list of articles, and scroll back to the top.
  #
  # Replacing every item would have the list tear down every row and build it
  # again, so items are only added or removed at the end, and the rows in view
  # are filled with the articles now at their positions.
  #
  # @param articles [Array<Article>] The articles to list.
  # @return [void]
  def replace_items(articles)
    count = @model.n_items

    @selection.unselect_all
    @model.splice([count, articles.size].min, [count - articles.size, 0].max,
                  (count...articles.size).map(&:to_s))
    @rows.rebind
    unless articles.empty?
      @view.scroll_to(0, :none, nil)
    end
  end

  # Select the row at a position and scroll it into view.
  #
  # @param position [Integer, nil] The position, where nil selects nothing.
  # @param focus [Boolean] Whether to move the keyboard focus to the row.
  # @return [void]
  def select_position(position, focus:)
    if position
      @view.scroll_to(position, focus ? %i(select focus) : :select, nil)
    end
  end

  # Return the position of the selected row.
  #
  # @return [Integer] The position, from zero.
  # @return [nil] When no row is selected.
  def selected_position
    position = @selection.selected

    if position < @model.n_items
      position
    end
  end
end
