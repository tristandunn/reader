# frozen_string_literal: true

module Memory
  TRIM = Fiddle::Function.new(Fiddle::Handle::DEFAULT["malloc_trim"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)

  module_function

  # Return freed memory to the operating system.
  #
  # Decoding an image allocates several times its size for a moment, and the
  # allocator keeps those pages after they are freed unless it is asked to
  # release them.
  #
  # @return [void]
  def trim
    GC.start

    TRIM.call(0)
  end
end
