# frozen_string_literal: true

class Timeline
  attr_reader :articles

  # Create the timeline of the articles in the article list.
  #
  # @param articles [Array<Article>] The articles, in the order they are listed.
  # @param state [ReadState] What decides which articles are unread.
  def initialize(articles, state)
    @articles = articles
    @state    = state
  end

  # Return the articles listed above an article, which are the newer ones.
  #
  # @param article [Article] The article to look above.
  # @return [Array<Article>] The articles, which are none when the article is not listed.
  def above(article)
    index = index(article)

    if index
      @articles.take(index)
    else
      []
    end
  end

  # Return the articles listed below an article, which are the older ones.
  #
  # @param article [Article] The article to look below.
  # @return [Array<Article>] The articles, which are none when the article is not listed.
  def below(article)
    index = index(article)

    if index
      @articles.drop(index + 1)
    else
      []
    end
  end

  # Return the article with an ID.
  #
  # @param id [String, nil] The ID of the article.
  # @return [Article] The article.
  # @return [nil] When no article has the ID.
  def find(id)
    @articles.find { |article| article.id == id }
  end

  # Return the position of an article.
  #
  # A refresh replaces the articles with fresh copies, so the article is found
  # by its ID rather than by identity.
  #
  # @param article [Article, nil] The article to find.
  # @return [Integer] The position, from zero.
  # @return [nil] When the article is not listed.
  def index(article)
    @articles.index { |candidate| candidate.id == article&.id }
  end

  # Return the next unread article after an article.
  #
  # The search goes down from the article and then wraps around to the top.
  #
  # @param article [Article, nil] The article to start after, which starts at the top when missing.
  # @return [Article] The unread article.
  # @return [nil] When no other article is unread.
  def next_unread(article)
    following(article).find { |candidate| !@state.read?(candidate) }
  end

  # Return how many of the articles are unread.
  #
  # @return [Integer] The count.
  def unread_count
    @articles.count { |article| !@state.read?(article) }
  end

  private

  # Return every other article in the order that follows an article, wrapping
  # around to the top.
  #
  # @param article [Article, nil] The article to start after.
  # @return [Array<Article>] The articles, which are all of them in order when the article is not listed.
  def following(article)
    index = index(article)

    if index
      @articles.rotate(index + 1).take(@articles.size - 1)
    else
      @articles
    end
  end
end
