# frozen_string_literal: true

module Shortcuts
  # The action that each key runs.
  ACTIONS = {
    "space"    => :scroll_or_next_unread,
    "n"        => :next_unread,
    "plus"     => :next_unread,
    "KP_Add"   => :next_unread,
    "r"        => :toggle_read,
    "u"        => :toggle_read,
    "k"        => :mark_all_read,
    "o"        => :mark_older_read,
    "l"        => :mark_all_read_and_next_unread,
    "m"        => :mark_unread_and_next_unread,
    "s"        => :toggle_star,
    "b"        => :open_in_browser,
    "Return"   => :open_in_browser,
    "KP_Enter" => :open_in_browser,
    "a"        => :previous_feed,
    "z"        => :next_feed,
    "Left"     => :focus_sidebar,
    "Right"    => :focus_article_list
  }.freeze

  COMMAND_ACTIONS = {
    ["r", %i(ctrl)]  => :reload,
    ["r", %i(super)] => :reload
  }.freeze

  module_function

  # Return the action for a key press.
  #
  # Most shortcuts are a plain key. Combinations with a command key, such as
  # Ctrl+A, are left to GTK and the desktop so that they keep their usual
  # meaning, except for the few that are listed as command shortcuts.
  #
  # @param key [String, nil] The GDK name of the key, such as `space` or `Left`.
  # @param modifiers [Array<Symbol>] The command keys held, from `:ctrl`, `:alt`, `:super` and `:meta`.
  # @return [Symbol] The action to run.
  # @return [nil] When the key press has no shortcut.
  def action_for(key, modifiers)
    if modifiers.empty?
      ACTIONS[key]
    else
      COMMAND_ACTIONS[[key, modifiers]]
    end
  end
end
