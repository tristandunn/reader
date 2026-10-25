# frozen_string_literal: true

class ReadState
  # Set whether the Feeds section of the sidebar is collapsed.
  #
  # @param value [Boolean] Whether the feeds should be hidden.
  # @return [void]
  attr_writer :feeds_collapsed

  # Load the state from its file, when there is one.
  #
  # @param path [String] The YAML file that holds the state.
  def initialize(path)
    @path            = path
    @read            = {}
    @starred         = {}
    @feeds_collapsed = false
    load
  end

  # Return whether the Feeds section of the sidebar is collapsed.
  #
  # @return [Boolean] Whether the feeds were left hidden.
  def feeds_collapsed?
    @feeds_collapsed
  end

  # Mark an article as read or as unread.
  #
  # @param article [Article] The article to mark.
  # @param read [Boolean] Whether the article should be read.
  # @return [void]
  def mark_read(article, read)
    if read
      @read[article.id] = Time.now.to_date.iso8601
    else
      @read.delete(article.id)
    end
  end

  # Forget the articles that were read longer ago than the window and are no
  # longer shown.
  #
  # An article that is still shown keeps its state however long ago it was read,
  # so that it does not come back as unread. The state is saved only when
  # something was forgotten.
  #
  # @param visible_ids [Set<String>] The IDs of the articles that are shown.
  # @return [void]
  def prune(visible_ids)
    cutoff = (Time.now.to_date - ARTICLE_MAX_AGE_DAYS).iso8601
    before = @read.size

    @read.delete_if { |id, read_on| read_on < cutoff && !visible_ids.include?(id) }
    if @read.size < before
      save
    end
  end

  # Return whether an article has been read.
  #
  # @param article [Article] The article to check.
  # @return [Boolean] Whether the article has been read.
  def read?(article)
    @read.key?(article.id)
  end

  # Write the state to its file.
  #
  # The state is written beside the file and then moved over it, so that a
  # crash while writing cannot leave half a file behind.
  #
  # @return [void]
  def save
    File.write("#{@path}.tmp",
               YAML.dump("read" => @read, "starred" => @starred.keys, "feeds_collapsed" => @feeds_collapsed))
    File.rename("#{@path}.tmp", @path)
  rescue StandardError => error
    warn "reader: cannot write #{@path}: #{error.message}"
  end

  # Return whether an article is starred.
  #
  # @param article [Article] The article to check.
  # @return [Boolean] Whether the article is starred.
  def starred?(article)
    @starred.key?(article.id)
  end

  # Star an article, or unstar it when it is starred.
  #
  # @param article [Article] The article to star or unstar.
  # @return [void]
  def toggle_star(article)
    if starred?(article)
      @starred.delete(article.id)
    else
      @starred[article.id] = true
    end
  end

  private

  # Return the read articles of a file, with the day each was read.
  #
  # Files from before articles were dated list the IDs alone, so those count as
  # read today. They then get the whole window before they can be forgotten.
  #
  # @param read [Hash{String => String}, Array<String>, nil] What the file holds under `read`.
  # @return [Hash{String => String}] The day each article was read, as `YYYY-MM-DD`.
  def dated(read)
    if read.is_a?(Hash)
      read.transform_values(&:to_s)
    else
      Array(read).to_h { |id| [id, Time.now.to_date.iso8601] }
    end
  end

  # Return the article IDs saved under a key.
  #
  # @param saved [Hash{String => Array}, nil] The contents of the file.
  # @param key [String] Either `read` or `starred`.
  # @return [Hash{String => true}] The IDs, as a lookup table.
  def ids(saved, key)
    Array(saved&.dig(key)).to_h { |id| [id, true] }
  end

  # Read the state from its file.
  #
  # @return [void]
  def load
    saved = YAML.safe_load_file(@path) if File.exist?(@path)
    @read = dated(saved&.dig("read"))
    @starred = ids(saved, "starred")
    @feeds_collapsed = saved&.dig("feeds_collapsed") == true
  rescue StandardError => error
    warn "reader: cannot read #{@path}: #{error.message}"
  end
end
