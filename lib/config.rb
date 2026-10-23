# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__) # Data is kept beside the script for now.
CONFIG_PATH = File.join(ROOT, "feeds.yml")
STATE_PATH = File.join(ROOT, "state.yml")
CACHE_DIR = File.join(ROOT, "cache")
IMAGE_DIR = File.join(CACHE_DIR, "images")
ICON_DIR = File.join(CACHE_DIR, "icons")
ICON_MAX_AGE = 7 * 24 * 60 * 60 # In seconds, before the icon of a feed is looked for again.
HOME_PAGE_MAX_BYTES = 512 * 1024 # Icons are linked in the head, near the top of a home page.
IMAGE_MAX_BYTES = 20 * 1024 * 1024
IMAGE_CACHE_MAX_BYTES = 200 * 1024 * 1024 # Images kept on disk before the least recently used go.
IMAGE_DOWNLOADERS = 4 # Images downloaded at once.
TRIM_DELAY = 500 # Milliseconds without a new image before memory is returned.
IMAGE_OVERSAMPLE = 2 # Pixels kept per pixel shown, so images stay sharp on high-resolution displays.
CACHE_MAX_AGE = 30 * 60 # In seconds.
FEED_FETCHERS = 6 # Feeds downloaded at once.
TODAY_SECONDS = 24 * 60 * 60 # How far back the Today smart feed reaches.
ARTICLES_PER_FEED = 100
ARTICLE_MAX_AGE_DAYS = 90 # Older articles are not shown, and what was read of them is forgotten.
SNIPPET_LENGTH = 140
SNIPPET_SOURCE_LENGTH = 2000 # Characters of an article read for its snippet, since parsing all of it is slow.
SNIPPET_SLACK = 32 # Extra text needed beyond the snippet, as the end of the characters read may be cut off.
TABLE_CELL_MAX_CHARS = 100 # Longest text a grid cell takes, beyond which a table is laid out as content.
COLUMN_PADDING = 96 # The left and right padding of the reading column, in pixels.
READER_MAX_WIDTH = 850 # About 68 characters of body text plus the padding, in pixels.

DEFAULT_FEEDS = <<~YAML
  - https://andre.arko.net/atom.xml
  - https://blog.fsck.com/feed/feed.xml
  - https://blog.jim-nielsen.com/feed.xml
  - https://boyter.org/index.xml
  - https://code.claude.com/docs/en/whats-new/rss.xml
  - https://dancroak.com/feed.xml
  - https://daringfireball.net/feeds/main
  - https://dbushell.com/rss.xml
  - https://evanhahn.com/blog/index.xml
  - https://fractaledmind.github.io/feed.xml
  - https://justin.searls.co/atom.xml
  - https://kyrylo.org/feed.xml
  - https://lethain.com/feeds.xml
  - https://lucumr.pocoo.org/feed.atom
  - https://mariochavez.io/feed.xml
  - https://masilotti.com/feed.xml
  - https://mikeperham.com/index.xml
  - https://mitchellh.com/feed.xml
  - https://paolino.me/feed.xml
  - https://simonwillison.net/atom/everything/
  - https://simplebits.com/feed.xml
  - https://stanko.io/articles/rss
  - https://staysaasy.com/feed.xml
  - https://til.simonwillison.net/tils/feed.atom
  - https://tristandunn.com/feed
  - https://www.dbreunig.com/feed.xml
  - https://www.germanvelasco.com/feed.xml
  - https://www.joeloliveira.com/rss.xml
  - https://www.philschmid.de/rss
  - https://www.schneems.com/feed.xml
  - https://www.writesoftwarewell.com/rss/
YAML
