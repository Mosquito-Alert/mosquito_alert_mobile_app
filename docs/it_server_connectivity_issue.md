# iOS app can’t reach apidev.mosquitoalert.com (TCP 443 refused)

## Summary
The iOS app is **not offline by logic**; it is **unable to establish a TCP connection** to the API host. DNS resolves, but the TCP handshake on port 443 is refused from the device network path.

## Evidence (from in-app diagnostics)
- **DNS** resolves: `apidev.mosquitoalert.com → 193.146.75.204`
- **TCP 443**: `SocketException: connection refused (errno = 61)`
- **HTTP /ping** fails with the same error (because TCP fails first)

This indicates the **server or a firewall/WAF in front of it is actively rejecting** the connection (or the port is closed) for the client path.

## What to check (server/network side)
1) **Firewall / WAF rules**
   - Ensure `193.146.75.204:443` is **open** to the public Internet.
   - Look for allow‑list rules that might block mobile networks or unknown IPs.
   - Confirm rate‑limits or geo‑filters are not rejecting mobile carrier IPs.

2) **Load balancer / reverse proxy**
   - Verify listener on 443 is active and healthy.
   - Confirm TLS termination is correctly configured (valid cert, SNI routing).
   - Check whether the proxy is **actively rejecting** connections (RST).

3) **IPv4 vs IPv6**
   - DNS is returning IPv4 only. Ensure IPv4 path is open.
   - If IPv6 is expected, publish AAAA records and verify IPv6 listener.

4) **Edge security / DDoS protection**
   - Some services drop or refuse TCP from mobile ASNs. Ensure ASNs for mobile carriers are allowed.

5) **Server logs**
   - Check for inbound connection attempts from the mobile device IPs.
   - If no logs exist, the connection is likely blocked upstream (firewall/WAF).

## How to validate quickly
- From a **mobile carrier network**, run a simple TCP test or curl:
  - `curl -I https://apidev.mosquitoalert.com/v1/ping`
- If this fails from mobile but works from office network, it confirms a **network policy issue** (allow‑list / firewall / WAF).

## Why this is not a Flutter / USB issue
- The error happens **inside the app**, not in the debugger.
- Flutter’s “Local Network permission” warning only affects IDE/debugger discovery, not app network traffic.

## Expected resolution
Once port 443 is reachable from mobile clients, the app should:
- create guest accounts,
- fetch user profile,
- sync outbox items.

If you need exact IPs, I can provide the device’s mobile IP from the diagnostic screen.
