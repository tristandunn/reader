# frozen_string_literal: true

if ENV.fetch("CI", ENV.fetch("COVERAGE", false))
  require "simplecov"
  require "simplecov-console"

  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start do
    coverage_dir "./tmp/coverage"
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
    cover "lib/**/*.rb"

    # These build GTK widgets, so they can't run without a display.
    %w(
      application article_actions article_header article_list article_row article_rows block_widgets column_fit
      feed_avatar feeds_heading image_view key_controller list_header main_window reader_pane reader_toolbar
      refresh_status refresher row_menu scaling sidebar sidebar_row style trim_scheduler ui
    ).each { |name| skip "lib/#{name}.rb" }
  end
end

require "digest"
require "fiddle"
require "fileutils"
require "nokogiri"
require "open-uri"
require "time"
require "tmpdir"
require "yaml"

%w(
  config memory text shortcuts column worker_pool article chronology timeline markup_tags image_tag block_runs
  table_rows article_blocks image_store image_downloader icon_links feed_icon monogram feed_cache feed_parser feed
  read_state library commands
).each { |name| require_relative "../lib/#{name}" }

Dir[File.join(__dir__, "support", "**", "*.rb")].each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # Enforce expect syntax.
    expectations.syntax = :expect

    # Include chained clauses in the descriptions of custom matchers.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevent mocking or stubbing a method that does not exist on a real object.
    mocks.verify_partial_doubles = true
  end

  # Inherit shared context metadata in host groups and examples.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Run specs in random order to surface order dependencies.
  config.order = :random

  # Seed global randomization so a failure can be reproduced with --seed.
  Kernel.srand config.seed

  # Raise errors for any deprecations.
  config.raise_errors_for_deprecations!
end
