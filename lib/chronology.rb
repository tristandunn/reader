# frozen_string_literal: true

module Chronology
  module_function

  # Insert an article into articles that are sorted newest first.
  #
  # An article goes above the first one that is as old or older, so it ends up
  # last when none is.
  #
  # @param articles [Array<Article>] The sorted articles, which gain the article.
  # @param article [Article] The article to insert.
  # @return [void]
  def insert(articles, article)
    position = articles.bsearch_index { |other| time(other) <= time(article) }

    articles.insert(position || articles.size, article)
  end

  # Sort articles with the newest first and the undated ones last.
  #
  # @param articles [Array<Article>] The articles to sort.
  # @return [Array<Article>] The sorted articles.
  def newest_first(articles)
    articles.sort_by { |article| time(article) }.reverse
  end

  # Return the time that an article is sorted by.
  #
  # @param article [Article] The article to sort.
  # @return [Time] The date of the article, which is the epoch for an undated one.
  def time(article)
    article.date || Time.at(0)
  end
end
