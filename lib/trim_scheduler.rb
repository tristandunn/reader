# frozen_string_literal: true

class TrimScheduler
  # Create a scheduler with nothing waiting.
  def initialize
    @source = nil
  end

  # Return freed memory to the operating system once calls stop arriving.
  #
  # Doing it for each image would collect garbage again and again while an
  # article's images load, so the wait starts over with every new call.
  #
  # @return [void]
  def schedule
    GLib::Source.remove(@source) if @source
    @source = GLib::Timeout.add(TRIM_DELAY) do
      @source = nil
      Memory.trim
      false # one-shot
    end
  end
end
