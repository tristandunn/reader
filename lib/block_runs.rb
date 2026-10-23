# frozen_string_literal: true

module BlockRuns
  MERGED = { quote: :quote, li: :list }.freeze

  module_function

  # Merge the runs of quotes and list items in a list of blocks.
  #
  # @param blocks [Array<Array>] The blocks, each a kind followed by its markup.
  # @return [Array<Array>] The blocks, with each run as one block holding the markup of its members.
  def merge(blocks)
    blocks.chunk_while { |first, second| mergeable?(first, second) }.map { |group| combine(group) }
  end

  # Return whether two consecutive blocks belong in one run.
  #
  # @param first [Array] The earlier block.
  # @param second [Array] The later block.
  # @return [Boolean] Whether both have the same kind and that kind merges.
  def mergeable?(first, second)
    first.first == second.first && MERGED.key?(first.first)
  end

  # Combine a run of blocks into a single block.
  #
  # @param group [Array<Array>] Consecutive blocks of one kind.
  # @return [Array] One block holding the markup of each member, or the lone block when its kind does not merge.
  def combine(group)
    kind = MERGED[group.first.first]

    if kind
      [kind, group.map(&:last)]
    else
      group.first
    end
  end
end
