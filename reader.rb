#!/usr/bin/env ruby
# frozen_string_literal: true

# A minimal RSS and Atom reader: a feed sidebar with unread counts, an article
# list, and a reading pane. Feeds are listed in feeds.yml next to this script.
# The file is created with a starter set of feeds on the first run.
#
# The keys are: space scrolls or goes to the next unread article, n goes to the
# next unread article, r or u toggles read, s toggles the star, k marks all as
# read, b or Return opens in the browser, a and z move between feeds, and
# Ctrl+R or Super+R refreshes.

require "gtk4"

require "digest"
require "fiddle"
require "fileutils"
require "nokogiri"
require "open-uri"
require "time"
require "yaml"

require_relative "lib/config"
require_relative "lib/style"
require_relative "lib/memory"
require_relative "lib/text"
require_relative "lib/shortcuts"
require_relative "lib/column"
require_relative "lib/worker_pool"
require_relative "lib/ui"
require_relative "lib/article"
require_relative "lib/chronology"
require_relative "lib/timeline"
require_relative "lib/markup_tags"
require_relative "lib/image_tag"
require_relative "lib/table_rows"
require_relative "lib/block_runs"
require_relative "lib/article_blocks"
require_relative "lib/image_store"
require_relative "lib/image_downloader"
require_relative "lib/icon_links"
require_relative "lib/feed_icon"
require_relative "lib/monogram"
require_relative "lib/feed_cache"
require_relative "lib/feed_parser"
require_relative "lib/feed"
require_relative "lib/read_state"
require_relative "lib/library"
require_relative "lib/commands"
require_relative "lib/scaling"
require_relative "lib/feed_avatar"
require_relative "lib/refresh_status"
require_relative "lib/sidebar_row"
require_relative "lib/feeds_heading"
require_relative "lib/sidebar"
require_relative "lib/refresher"
require_relative "lib/row_menu"
require_relative "lib/article_row"
require_relative "lib/article_rows"
require_relative "lib/article_list"
require_relative "lib/trim_scheduler"
require_relative "lib/image_view"
require_relative "lib/block_widgets"
require_relative "lib/article_header"
require_relative "lib/column_fit"
require_relative "lib/reader_pane"
require_relative "lib/article_actions"
require_relative "lib/list_header"
require_relative "lib/reader_toolbar"
require_relative "lib/key_controller"
require_relative "lib/main_window"
require_relative "lib/application"

Reader.new.run
