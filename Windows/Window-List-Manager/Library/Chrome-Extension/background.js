const endpoint = "http://127.0.0.1:18763/domains";
let pending, transfer_retry, poll, in_flight = false;
let state, client_id;
const activated = new Set();

/* Restore profile identity and session observations before sending snapshots. */
const ready = (async () => {
  const local = await chrome.storage.local.get("domain_client_id");
  client_id = local.domain_client_id || crypto.randomUUID();
  if (!local.domain_client_id) await chrome.storage.local.set({ domain_client_id: client_id });
  const session = await chrome.storage.session.get("domain_state");
  state = session.domain_state || { pages: {}, processed: [], acks: [] };
})();

/* HTTP(S) URLs alone may enter history or browser commands. */
function validUrl(value) {
  if (typeof value !== "string") return false;
  try { const u = new URL(value); return (u.protocol === "http:" || u.protocol === "https:") && !/[\t\r\n]/.test(value); } catch (_) { return false; }
}

/* Detach a specific existing tab only while its source still has multiple tabs. */
async function detachChromeTabCommand(command)
{
  const window_id = Number(command.window_id);
  const tab_id = Number(command.tab_id);
  if (!Number.isSafeInteger(window_id) || window_id <= 0 || !Number.isSafeInteger(tab_id) || tab_id <= 0)
    throw new Error("Invalid Chrome tab detach target.");

  let source_window, tab;
  try {
    source_window = await chrome.windows.get(window_id);
    tab = await chrome.tabs.get(tab_id);
  } catch (_) {
    return "stale";
  }
  if ((source_window.type !== "normal" && source_window.type !== "popup") || source_window.incognito
      || tab.windowId !== window_id || !tab.active || tab.incognito)
    return "stale";

  const source_tabs = await chrome.tabs.query({windowId: window_id});
  if (source_tabs.length < 2)
    return "single-tab";

  const was_pinned = Boolean(tab.pinned);
  if (was_pinned)
    await chrome.tabs.update(tab_id, {pinned: false});
  try {
    await chrome.windows.create({tabId: tab_id, type: "normal", focused: true});
  } catch (error) {
    if (was_pinned) {
      try { await chrome.tabs.update(tab_id, {pinned: true}); } catch (_) {}
    }
    throw error;
  }
  if (was_pinned)
    await chrome.tabs.update(tab_id, {pinned: true});
  return "detached";
}

/* Serialize polls, keep event recency stable, and retry when the bridge returns. */
async function sendDomains() {
  if (in_flight) return;
  in_flight = true;
  let connected = false;
  try {
    await ready;
    const all_windows = await chrome.windows.getAll({ populate: true });
    const pages = {};
    const windows = all_windows.filter(w => !w.incognito && (w.type === "normal" || w.type === "popup")).map(w => {
      const tab = w.tabs?.find(t => t.active && !t.incognito);
      const url = validUrl(tab?.url) ? tab.url : "";
      const previous = state.pages[w.id];
      const changed = !previous || previous.url !== url || previous.tab_id !== tab?.id || activated.has(w.id);
      const page = { url, tab_id: tab?.id ?? -1, visited_at: changed ? Date.now() : previous.visited_at, visit_id: changed ? crypto.randomUUID() : previous.visit_id };
      pages[w.id] = page;
      return { title: tab?.title || "", domain: url ? new URL(url).hostname.toLowerCase() : "", left: w.left || 0, top: w.top || 0, width: w.width || 0, height: w.height || 0, ...page, window_id: w.id, tab_count: (w.tabs || []).length };
    });
    activated.clear();
    state.pages = pages;
    await chrome.storage.session.set({ domain_state: state });
    const sent_acks = [...state.acks];
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 4000);
    let response;
    try {
      response = await fetch(endpoint, { method: "POST", headers: { "Content-Type": "text/plain" }, body: JSON.stringify({ api_version: 2, client_id, windows, acks: sent_acks }), signal: controller.signal });
      if (!response.ok) throw new Error("bridge response");
      const reply = await response.json();
      state.acks = state.acks.filter(id => !sent_acks.includes(id));
      for (const command of (reply.api_version === 2 && Array.isArray(reply.commands) ? reply.commands.slice(0, 10) : [])) {
        if (!command || typeof command.id !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(command.id || "")) continue;
        if (command.type !== "detach_tab" && (command.type !== "open_url" || !validUrl(command.url))) continue;
        if (!state.processed.includes(command.id)) {
          try {
            if (command.type === "detach_tab")
              await detachChromeTabCommand(command);
            else
              await chrome.windows.create({ url: command.url, type: "normal", focused: true });
          } catch (_) { continue; }
          state.processed.push(command.id);
          state.processed = state.processed.slice(-512);
        }
        if (!state.acks.includes(command.id)) state.acks.push(command.id);
      }
      state.acks = state.acks.slice(-512);
      await chrome.storage.session.set({ domain_state: state });
      connected = true;
    } finally { clearTimeout(timeout); }
  } catch (_) { /* Poll again even without a Chrome activation event. */ }
  finally { in_flight = false; clearTimeout(poll); poll = setTimeout(sendDomains, connected ? 2000 : 5000); }
}

/* Coalesce ordinary Chrome updates. */
function scheduleUpdate() { clearTimeout(pending); pending = setTimeout(sendDomains, 300); }
/* Refresh again after Chrome finishes moving a tab between windows. */
function scheduleTransferUpdate() { scheduleUpdate(); clearTimeout(transfer_retry); transfer_retry = setTimeout(sendDomains, 1500); }
chrome.tabs.onAttached.addListener(scheduleTransferUpdate);
chrome.tabs.onDetached.addListener(scheduleTransferUpdate);
chrome.tabs.onCreated.addListener(scheduleTransferUpdate);
chrome.tabs.onActivated.addListener(info => { activated.add(info.windowId); scheduleUpdate(); });
chrome.tabs.onUpdated.addListener(scheduleUpdate);
chrome.tabs.onRemoved.addListener(scheduleUpdate);
chrome.windows.onCreated.addListener(scheduleUpdate);
chrome.windows.onRemoved.addListener(scheduleUpdate);
chrome.windows.onFocusChanged.addListener(id => { if (id >= 0) activated.add(id); scheduleUpdate(); });
chrome.windows.onBoundsChanged.addListener(scheduleUpdate);
chrome.runtime.onStartup.addListener(scheduleUpdate);
chrome.runtime.onInstalled.addListener(scheduleUpdate);
chrome.alarms.onAlarm.addListener(scheduleUpdate);
chrome.alarms.create("domain-sync", { periodInMinutes: 0.5 });
scheduleUpdate();

