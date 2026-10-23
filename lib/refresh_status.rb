# frozen_string_literal: true

class RefreshStatus
  include Ui

  attr_reader :widget

  # Build the status, which stays hidden until a refresh reports progress.
  def initialize
    @bar    = build(Gtk::ProgressBar, css: "refresh-bar", hexpand: false, valign: :center)
    @label  = label("", "refresh-label")
    @widget = box(:horizontal, 10, [@bar, @label], css: "refresh-status", visible: false)
  end

  # Hide the status.
  #
  # @return [void]
  def hide
    @widget.visible = false
  end

  # Show how many of the feeds have been loaded.
  #
  # @param done [Integer] How many feeds have been loaded.
  # @param total [Integer] How many feeds there are.
  # @return [void]
  def update(done, total)
    @bar.fraction = fraction(done, total)
    @label.text   = "#{done} of #{total} feeds"
    @widget.visible = true
  end

  private

  # Return how much of the work is done.
  #
  # @param done [Integer] How many feeds have been loaded.
  # @param total [Integer] How many feeds there are.
  # @return [Float] A fraction from zero to one, which is zero when there are no feeds.
  def fraction(done, total)
    if total.zero?
      0.0
    else
      done.fdiv(total)
    end
  end
end
