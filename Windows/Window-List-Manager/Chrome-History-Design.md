# Window List Manager — Chrome history design

Status: user approved; implemented in manager 0.232 and extension 0.1.3, with Options lifecycle fix in manager 0.233. Node and static checks passed; Windows end-to-end verification remains outstanding.
Base: Window List Manager 0.231 and its existing Window List Manager Domains extension.
Chome-Window-Grid is a separate project and is outside this change.

## Requested behavior

- Keep two separate lists within the existing manager dialog.
- Anchor the open-window list below the title strip at the top.
- Anchor the Chrome history list above the bottom edge.
- Keep history across restarts, including full URLs and page titles.
- Add a domain option to enable history collection.
- Add a configurable retained-page count, default 20.
- Give history its own Alphabetical / Recent ordering.

## Confirmed behavior

- The limit is 20 distinct pages per enabled domain, rather than 20 across all domains.
- Record the active HTTP/HTTPS page seen in each Chrome window while the manager is running.
- This is manager-collected history, not an import of Chrome's full browsing-history database.
- Repeated observations of an unchanged page do not create duplicates or continuously advance its recency.
- Seeing a page again after navigation/activation updates its title and last-seen ordering.
- Use the existing normalized hostname and nearest parent-domain rule behavior for enabling collection.
- History rows show page titles; their complete URLs are available on hover and through Copy URL.
- Double-clicking a history row opens its saved URL in a Chrome window through the extension.
- Keep the live-window single-click preview and double-click expansion behavior unchanged.
- Initially divide the available list area equally; provide a draggable divider and remember its position.
- If history is disabled, the open-window list uses the available height.
- Disabling collection keeps previously saved history; removing history requires an explicit clear action.
- Reducing the limit retains the newest pages, regardless of the display's alphabetical/recent mode.

## Approach and module boundaries

Use the existing AHK manager, existing local-only bridge and existing Domains extension.
The user explicitly chose this approach. Integrating Chome-Window-Grid was considered
and rejected by the user; collecting URLs through window titles or the clipboard
cannot supply dependable full URLs and is not proposed.

Keep Chrome capture and Chrome window actions inside the extension. Keep history
persistence, retention and list presentation in a separate manager history module.
Extend the local API with versioned page snapshots and bounded URL-open commands.
Retain compatibility with older domain-only snapshots: live grouping still works,
and the history area explains when the extension needs updating. The two codebases
remain independently maintained; no copied Chrome-Grid layout/session functionality.

The implementation must preserve Chrome normal/popup support and carry a profile/
client identity so URL-open commands are handled by the extension that reported
the page. Validate URLs as HTTP/HTTPS data before opening them. No public listener
or Chrome history-database permission is required.

## Verification to include

- Extension tests: full URLs, normal/popup windows, navigation, duplicates and URL-open commands.
- History tests: persistence, domain enablement/inheritance, exact URLs, retention default 20,
  reducing the limit, alphabetical/recent order and corrupt-file recovery.
- Bridge tests: old snapshots, new snapshots, unsupported commands and separate clients.
- AHK regression coverage: top/bottom anchoring, splitter limits, live-window actions,
  history opening, and persistence after restart.
- Windows GUI execution and Chrome extension reload remain required for end-to-end verification.

## Delivery

Increment the manager version by 0.001 and the companion extension version.
Update the existing extension package, installer instructions and test files.
Keep Drive file identities when updating existing files; create a new versioned
manager implementation in Lib. Do not change Chome-Window-Grid files.
