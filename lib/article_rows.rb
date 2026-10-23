# frozen_string_literal: true

class ArticleRows
  attr_reader :factory

  # Create what builds the rows of the article list and fills them as it
  # scrolls.
  #
  # The list only asks for rows in view, and hands each one back to be filled
  # with another article, so the rows that are showing are tracked to fill or
  # restyle them again when the articles change.
  #
  # @param state [ReadState] What decides how the rows are styled.
  # @param menu [RowMenu] What pops up on a right-click.
  # @param timeline [#call] Called to get the {Timeline} whose articles the rows show.
  def initialize(state, menu:, timeline:)
    @state    = state
    @menu     = menu
    @timeline = timeline
    @rows     = {}.compare_by_identity # list item => row
    @bound    = {}.compare_by_identity # list item => row in view
    @factory  = build_factory
  end

  # Fill the rows in view again with the articles now at their positions.
  #
  # The list unbinds the rows of removed items only later, so a row can still
  # be bound to an item past the end, which has no article to show.
  #
  # @return [void]
  def rebind
    @bound.each do |item, row|
      article = @timeline.call.articles[item.position]

      if article
        row.bind(article)
      end
    end
  end

  # Update the styling of the row of an article, if it is in view.
  #
  # @param article [Article] The article whose row to update.
  # @return [void]
  def restyle(article)
    @bound.each_value.find { |row| row.article.id == article.id }&.restyle
  end

  # Update the styling of every row in view.
  #
  # @return [void]
  def restyle_all
    @bound.each_value(&:restyle)
  end

  private

  # Fill a row with the article at its position.
  #
  # @param item [Gtk::ListItem] The item of the row.
  # @return [void]
  def bind(item)
    row = @rows[item]

    row.bind(@timeline.call.articles[item.position])
    @bound[item] = row
  end

  # Build the factory that the list asks for rows.
  #
  # The rows are tracked by their list items, which stay the same from setup
  # to teardown, so that a row the list tears down can be forgotten.
  #
  # @return [Gtk::SignalListItemFactory] The factory.
  def build_factory
    factory = Gtk::SignalListItemFactory.new

    factory.signal_connect("setup") { |_factory, item| setup(item) }
    factory.signal_connect("bind") { |_factory, item| bind(item) }
    factory.signal_connect("unbind") { |_factory, item| @bound.delete(item) }
    factory.signal_connect("teardown") { |_factory, item| @rows.delete(item) }
    factory
  end

  # Build an empty row for the list to fill.
  #
  # @param item [Gtk::ListItem] The item that holds the row.
  # @return [void]
  def setup(item)
    row = ArticleRow.new(@state, menu: @menu)

    item.child  = row.widget
    @rows[item] = row
  end
end
