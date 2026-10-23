# frozen_string_literal: true

CSS = <<~STYLE
  /* Colors. The dark set follows the color scheme of the desktop. */
  :root {
    --accent: #2c6be0;
    --on-accent: #ffffff;
    --canvas: #ffffff;
    --sidebar: #f3f3f6;
    --text: #1d1d20;
    --text-secondary: #6b6b74;
    --text-tertiary: #a0a0a8;
    --separator: #e4e4e9;
    --hover: rgba(0, 0, 0, 0.04);
    --muted-selection: rgba(0, 0, 0, 0.075);
    --star: #ee9d12;
    --today: #f0772e;
    --well: #f4f4f7;
    --code-text: #000000;
    --quote-bar: #d8d8de;
    --link: #2460cc;
  }

  @media (prefers-color-scheme: dark) {
    :root {
      --accent: #3a78ef;
      --canvas: #1c1c1f;
      --sidebar: #242428;
      --text: #ececf0;
      --text-secondary: #a2a2aa;
      --text-tertiary: #6e6e77;
      --separator: #323237;
      --hover: rgba(255, 255, 255, 0.05);
      --muted-selection: rgba(255, 255, 255, 0.09);
      --star: #f5b23a;
      --today: #f58a4b;
      --well: #2a2a2f;
      --code-text: #f4f4f7;
      --quote-bar: #46464d;
      --link: #74a6ff;
    }
  }

  window.reader-window { background-color: var(--canvas); color: var(--text); }
  paned > separator { background-color: var(--separator); min-width: 1px; }
  /* The handle of a pane is wider than its line, and the columns paint over the rest. */
  .content-column { background-color: var(--canvas); }

  /* Each pane has its own header, so the toolbar lines up with the columns. */
  headerbar.pane-header,
  headerbar.pane-header:backdrop {
    background: transparent;
    border: none;
    box-shadow: none;
    min-height: 48px;
    padding: 0 10px;
  }
  .pane-title { color: var(--text); font-size: 14px; font-weight: 700; }
  .pane-subtitle { color: var(--text-secondary); font-size: 12px; }

  .toolbar-button {
    background: none;
    border: none;
    border-radius: 7px;
    box-shadow: none;
    color: var(--text-secondary);
    min-height: 30px;
    min-width: 32px;
    padding: 0;
  }
  .toolbar-button:hover { background-color: var(--hover); color: var(--text); }
  .toolbar-button:checked { background-color: var(--muted-selection); color: var(--accent); }
  .toolbar-button:active { background-color: var(--muted-selection); }
  .toolbar-button:disabled { opacity: 0.35; }
  .toolbar-button.starred { color: var(--star); }

  /* Feed icons, with a lettered tile for a feed that has none. */
  .avatar { border-radius: 4px; }
  .monogram {
    border-radius: 4px;
    color: #ffffff;
    font-size: 10px;
    font-weight: 800;
  }
  .monogram.large { border-radius: 5px; font-size: 12px; }
  .tint-0 { background-color: #e0564e; }
  .tint-1 { background-color: #e8833a; }
  .tint-2 { background-color: #c9a227; }
  .tint-3 { background-color: #4fa463; }
  .tint-4 { background-color: #2f9c9a; }
  .tint-5 { background-color: #3d7fd9; }
  .tint-6 { background-color: #7c62d6; }
  .tint-7 { background-color: #c75a9c; }

  /* Sidebar. The selection is the accent color only while the list has focus. */
  .sidebar-column { background-color: var(--sidebar); }
  .sidebar { background: transparent; padding: 0 0 10px 0; }
  .sidebar row {
    background: none;
    border-radius: 7px;
    margin: 1px 10px;
    min-height: 30px;
    outline: none;
    padding: 0 0 0 9px;
  }
  .sidebar row:hover { background-color: var(--hover); }
  .sidebar row:selected { background-color: var(--muted-selection); }
  .sidebar:focus-within row:selected { background-color: var(--accent); }
  .sidebar:focus-within row:selected .feed-name,
  .sidebar:focus-within row:selected .count,
  .sidebar:focus-within row:selected .sidebar-icon { color: var(--on-accent); }
  .sidebar row.heading-row,
  .sidebar row.heading-row:hover { background: none; }
  .sidebar .feed-name { color: var(--text); font-size: 13.5px; padding: 0 6px 0 9px; }
  .sidebar .count {
    color: var(--text-secondary);
    font-feature-settings: "tnum";
    font-size: 12px;
    font-weight: 600;
    padding: 0 10px 0 4px;
  }
  .sidebar .heading {
    color: var(--text-tertiary);
    font-size: 11.5px;
    font-weight: 700;
    padding: 16px 0 4px 2px;
  }
  .sidebar .heading-arrow { color: var(--text-tertiary); margin: 16px 10px 4px 0; }
  .sidebar-icon { color: var(--accent); }
  .sidebar-icon.today { color: var(--today); }
  .sidebar-icon.starred { color: var(--star); }

  .refresh-status { border-top: 1px solid var(--separator); padding: 10px 16px 12px 16px; }
  .refresh-label { color: var(--text-secondary); font-size: 12px; }
  .refresh-status trough {
    background-color: var(--separator);
    border-radius: 2px;
    min-height: 4px;
    min-width: 64px;
  }
  .refresh-status progress { background-color: var(--accent); border-radius: 2px; min-height: 4px; }

  /* Article list. Separators start at the text, and hide beside a selection. */
  .articles { background-color: var(--canvas); padding: 0 0 8px 0; }
  .articles > row {
    background: none;
    border-radius: 9px;
    margin: 0 8px;
    outline: none;
    padding: 0;
  }
  .articles > row:hover { background-color: var(--hover); }
  .articles > row:selected { background-color: var(--muted-selection); }
  .articles:focus-within > row:selected { background-color: var(--accent); }
  .article-gutter { min-width: 22px; padding-top: 14px; }
  .article-avatar { padding: 11px 9px 0 0; }
  .article-text { border-bottom: 1px solid var(--separator); padding: 10px 12px 11px 0; }
  .articles > row:selected .article-text { border-color: transparent; }
  .unread-dot { background-color: var(--accent); border-radius: 4px; min-height: 8px; min-width: 8px; }
  .star-mark { color: var(--star); }
  .article-title { color: var(--text); font-size: 14px; font-weight: 700; }
  .read .article-title { font-weight: 500; }
  .article-snippet { color: var(--text-secondary); font-size: 13px; }
  .article-source, .article-date { color: var(--text-tertiary); font-size: 12px; }
  /* Named, not "label": the context menu is parented to the row and must keep its own colors. */
  .articles:focus-within > row:selected .article-title,
  .articles:focus-within > row:selected .article-snippet,
  .articles:focus-within > row:selected .article-source,
  .articles:focus-within > row:selected .article-date,
  .articles:focus-within > row:selected .star-mark { color: var(--on-accent); }
  .articles:focus-within > row:selected .unread-dot { background-color: var(--on-accent); }

  /* Reading pane. */
  .reader, .reader > viewport { background-color: var(--canvas); }
  .reader-column { padding: 30px 48px 72px 48px; }
  .reader-source { color: var(--link); font-size: 13px; font-weight: 600; }
  .reader-title {
    color: var(--text);
    font-size: 28px;
    font-weight: 800;
    letter-spacing: -0.3px;
    line-height: 1.2;
  }
  .reader-date { color: var(--text-secondary); font-size: 13px; }
  .reader-rule { background-color: var(--separator); margin: 18px 0 14px 0; min-height: 1px; }
  .body-p { color: var(--text); font-size: 19px; line-height: 1.6; }
  .body-h { color: var(--text); font-size: 21px; font-weight: 700; line-height: 1.3; padding-top: 8px; }
  .body-quote { border-left: 3px solid var(--quote-bar); padding-left: 16px; }
  .body-quote .body-p { color: var(--text-secondary); }
  .body-pre {
    background-color: var(--well);
    border-radius: 8px;
    color: var(--code-text);
    font-family: "Monaspace Neon Var", monospace;
    font-size: 16px;
    line-height: 1.55;
    padding: 14px 16px;
  }
  .body-table { border-left: 1px solid var(--separator); border-top: 1px solid var(--separator); }
  .body-cell {
    border-bottom: 1px solid var(--separator);
    border-right: 1px solid var(--separator);
    font-size: 15px;
    line-height: 1.4;
    padding: 6px 12px;
  }
  .body-th { background-color: var(--well); }
  .body-image { border-radius: 8px; }
  .body-bullet { color: var(--text-secondary); min-width: 14px; }
  .reader label link, .reader label link:visited { color: var(--link); }

  .empty-state { color: var(--text-tertiary); font-size: 15px; }
  .empty-icon { color: var(--text-tertiary); opacity: 0.6; }
STYLE
