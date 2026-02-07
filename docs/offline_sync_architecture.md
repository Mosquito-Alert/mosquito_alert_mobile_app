# Offline/Online Sync Architecture (iOS + Android)

## Summary (why change)
The app currently uses a server “ping” to decide whether it is online. On iOS this has proven brittle because:
- a single endpoint failure (or auth/interceptor error) marks the app “offline” even when the device has connectivity,
- a failed ping prevents retries even though the device could still submit queued items,
- it creates false negatives that confuse users.

This refactor shifts the source of truth from “connectivity checks” to **actual sync outcomes**. The goal is: **attempt sync; if it succeeds, mark items as synced; if it fails, keep them queued and retry later**.

## Core principles
1. **Sync success/failure is truth**
   - Attempt to sync immediately on item creation and on app start.
   - If sync fails due to network/server, keep items in outbox.
   - If sync fails due to 4xx validation, mark item as failed (do not retry forever).

2. **Connectivity is only a hint**
   - Use OS connectivity events *only* to trigger a retry.
   - Never block sync attempts because a ping said “offline.”

3. **UI shows sync state, not global “offline state”**
   - Per‑item state (queued/syncing/failed) is clearer and avoids false “offline” banners.

4. **Retry with exponential backoff**
   - Example delays: 1m → 5m → 15m → 1h
   - Retry on connectivity hint, app start, and manual “retry now.”

5. **Auth failures are not “offline”**
   - 401/403 should trigger re‑auth or guest creation, not offline status.

## Concrete refactor in this branch
### ✅ Remove ping‑based offline gating
- No server “ping” is used to decide online/offline.
- Connectivity signals are used only to trigger sync attempts.

### ✅ Add a lightweight sync controller with backoff
A new `OutboxSyncController`:
- triggers sync on app start,
- triggers sync on connectivity “connected” hints,
- schedules retries with backoff when items remain pending.

### ✅ Keep per‑item offline UI
The existing per‑item icons (e.g., cloud‑off) continue to represent queued items.
The global “Offline mode” banner is removed to avoid false negatives.

### ✅ Background tracking uses the same outbox semantics
Background tracking uses `FixesRepository.create(...)`, which enqueues items
and retries later if the immediate send fails. No UI is required for background
fixes; they are treated as “queue‑and‑retry.”

### ✅ Onboarding is not blocked by offline auth
Guest account creation is now **deferred** if it fails due to network issues.
Onboarding completes, and the app will retry guest creation when connectivity
returns. This prevents the “Turn on location” step from blocking offline users.

### ✅ Layout no longer blocks on user fetch when offline
If the user profile cannot be fetched and guest creation is deferred, the app
continues into the main UI instead of showing the “loading failed” retry page.

### ✅ Network requests bypass system proxies (robust connectivity)
The API client now uses **direct sockets** (no system proxy/PAC). This avoids
cases where iOS proxies/content filters allow Safari but block app traffic,
which can surface as `SocketException: Connection refused`.

## Minimal flow (pseudocode)
```
onAppStart:
  syncController.triggerSync(reason: startup)

onConnectivityConnected:
  restoreSessionIfNeeded()
  syncController.triggerSync(reason: connectivity)

syncController.triggerSync:
  if already syncing -> return
  attempt syncAll()
  if items remain pending -> schedule retry (backoff)
  else reset backoff
```

## Recommended follow‑ups (optional)
- Add “Syncing…” and “X items pending” indicators in a non‑blocking place.
- Add a “Retry now” button in the outbox screen.
- Track per‑item failure reason (network vs validation) to avoid infinite retries.
- Persist next retry time so backoff survives app restarts.

---
This architecture avoids false offline status, keeps sync reliable, and matches how offline‑first apps are expected to behave.
