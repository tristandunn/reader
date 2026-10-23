# frozen_string_literal: true

class Reader
  # Run the application until its window is closed.
  #
  # @return [void]
  def run
    application = Gtk::Application.new("com.example.reader", :default_flags)

    application.signal_connect("activate") { |instance| activate(instance) }
    application.run([$PROGRAM_NAME] + ARGV)
  end

  private

  # Build the window from the cached feeds, then refresh them in the background.
  #
  # @param application [Gtk::Application] The application whose window to build.
  # @return [void]
  def activate(application)
    state   = ReadState.new(STATE_PATH)
    library = Library.new(Feed.load_all, state)

    install_css
    library.replace(library.load(refresh: false))

    window = MainWindow.new(application, library, state)

    window.present
    window.reload
  end

  # Load the stylesheet into the default display, so it applies to every widget.
  #
  # GTK only tells its own stylesheets whether the desktop prefers a dark color
  # scheme, so this one is bound to the setting to follow it as it changes.
  #
  # @return [void]
  def install_css
    provider = Gtk::CssProvider.new

    Gtk::Settings.default.bind_property("gtk-interface-color-scheme", provider, "prefers-color-scheme", :sync_create)

    begin
      provider.load(data: CSS)
    rescue NoMethodError, ArgumentError
      provider.load_from_data(CSS)
    end

    Gtk::StyleContext.add_provider_for_display(
      Gdk::Display.default, provider, Gtk::StyleProvider::PRIORITY_APPLICATION
    )
  end
end
