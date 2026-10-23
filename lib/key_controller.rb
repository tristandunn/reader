# frozen_string_literal: true

class KeyController
  COMMAND_MODIFIERS = {
    ctrl:  Gdk::ModifierType::CONTROL_MASK,
    alt:   Gdk::ModifierType::ALT_MASK,
    super: Gdk::ModifierType::SUPER_MASK,
    meta:  Gdk::ModifierType::META_MASK
  }.freeze

  # Add the keyboard shortcuts to a window.
  #
  # The keys are caught before the focused widget sees them, since a list would
  # otherwise take Space and Return for itself. The window has no text entry,
  # so no typing is lost.
  #
  # @param window [Gtk::Window] The window to add the shortcuts to.
  # @param commands [Commands] What runs each action of {Shortcuts}, by the name of the action.
  def initialize(window, commands)
    @commands = commands
    keys      = Gtk::EventControllerKey.new
    keys.propagation_phase = :capture

    keys.signal_connect("key-pressed") do |_controller, keyval, _keycode, state|
      action = action_for(keyval, state)

      @commands.public_send(action) if action
      !action.nil?
    end
    window.add_controller(keys)
  end

  private

  # Return the action for a key press.
  #
  # @param keyval [Integer] The GDK key value.
  # @param state [Gdk::ModifierType] The modifier keys that are held.
  # @return [Symbol] The action to run.
  # @return [nil] When the key press has no action.
  def action_for(keyval, state)
    Shortcuts.action_for(Gdk::Keyval.to_name(keyval), modifiers(state))
  end

  # Return the command keys that are held.
  #
  # @param state [Gdk::ModifierType] The modifier keys that are held.
  # @return [Array<Symbol>] From `:ctrl`, `:alt`, `:super` and `:meta`.
  def modifiers(state)
    COMMAND_MODIFIERS.reject { |_name, mask| (state & mask).to_i.zero? }.keys
  end
end
