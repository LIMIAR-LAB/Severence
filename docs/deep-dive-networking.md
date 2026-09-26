# Deep Dive — Networking / Multiplayer

**Date:** 2026-09-25 · Source: `scripts/main.gd`

## 1. Topology

- **Transport:** Godot's built-in high-level multiplayer API over `ENetMultiplayerPeer`.
- **Port:** fixed `24871` UDP (`const PORT := 24871`), no port negotiation/fallback.
- **Roles:** exactly one host + one guest ("P2"). No lobby, no relay/NAT traversal/UPnP, no matchmaking — the host must be directly reachable at the chosen IP:port (loopback `127.0.0.1` for same-machine testing, LAN IP otherwise; cross-network play requires manual port forwarding, not automated by the game).
- **Authority model:** fully host-authoritative. The host runs the *real* `Expedition` simulation (`sim.step(...)`); the client never calls `sim.step()` on its own copy — it only ever calls `sim.apply_snapshot()` with data received from the host. There is no client-side prediction or reconciliation (explicitly called out as a known limitation in `README.md`: "latência elevada ainda pode causar atraso perceptível").

## 2. Connection Lifecycle

| Step | Host side | Client side |
|---|---|---|
| Start | `host_game()`: create `ENetMultiplayerPeer`, `peer.create_server(PORT, 1)`, `sim.coop = "ai"` (AI fills P2 until someone joins) | `join_game()`: `peer.create_client(ip, PORT)`, shows "Conectando..." |
| Peer joins | `peer_connected(id)`: stores `guest_id`, flips `sim.coop = "online"`, activates/revives `actors[1]`, updates status text | `connected()`: sets `playing = true`, closes menu |
| Peer leaves | `peer_disconnected(id)`: if it was the guest, resets `guest_id = 0`, `sim.coop = "ai"` (AI reclaims P2), clears `remote_cmd` | `server_disconnected()`: disconnects, keeps local progress, reopens menu with a status message |
| Failure | — | `connection_failed()`: disconnects, shows a message pointing at IP/firewall/port 24871 |

`disconnect_network()` is the single teardown path used by every mode switch (solo/local/host/join) to guarantee a clean peer/state reset before starting a new mode.

## 3. Per-Frame Protocol

### Client → Host: `submit_input`
```gdscript
@rpc("any_peer", "call_remote", "reliable", 1)
func submit_input(data: Dictionary) -> void
```
- Called every `_physics_process` from the client with its locally-read `player_input(1)` command dictionary (or an empty `{}` while its menu is open, to stop moving without a full pause).
- **Host-side validation is a strict allow-list**, not a passthrough: only `move`/`aim` (as finite `Vector2`s, then `limit_length()`'d) and the 10 known boolean action keys are copied into `remote_cmd`; anything else in the payload is silently dropped. This is the only place client-supplied data crosses into host simulation input.
- Host also checks `multiplayer.get_remote_sender_id() != guest_id` and rejects otherwise — a stray/second peer can't inject input for P2.
- **Staleness guard:** the host only *uses* `remote_cmd` if `remote_age < 0.4s` since the last received packet (`remote_age` incremented every host frame, reset to 0 on receipt) — if the guest's connection stalls, P2 simply stops acting rather than repeating a stale command forever.

### Host → Client: `receive_state`
```gdscript
@rpc("authority", "call_remote", "reliable", 2)
func receive_state(packet: PackedByteArray) -> void
```
- Sent every **0.05s** (20 Hz) from the host's `_physics_process`, only while `hosting and guest_id > 0`.
- Payload: `var_to_bytes(sim.snapshot()).compress(FileAccess.COMPRESSION_DEFLATE)` — the *entire* game-state dictionary (~30 top-level fields, see `architecture.md` §3), zlib-compressed. No delta/diff encoding.
- Client decompresses with a **1 MB cap** (`decompress_dynamic(1048576, ...)`) and rejects payloads that don't decode to a `Dictionary`, then calls `sim.apply_snapshot(data)` — fully overwriting its local simulation state every packet.
- Uses RPC channel `2` (distinct from `submit_input`'s channel `1`) — separate ordered-reliable channels, so state and input delivery don't head-of-line-block each other.

### Equipment/Robot requests (guest-initiated actions)
```gdscript
request_loadout(id, outfit, robot, armor_type)  # local dispatcher in main.gd
@rpc("any_peer", "call_remote", "reliable", 3) func change_loadout(outfit, robot, armor_type)
request_robot_action(id, action)  # "summon" | "fusion"
@rpc("any_peer", "call_remote", "reliable", 3) func robot_action(action)
```
- If called on the **guest**, these don't touch `sim` directly — they RPC the request to peer id `1` (the host), which validates (`multiplayer.get_remote_sender_id() == guest_id`) and only then calls the real `sim.equip()` / `sim.summon_robot()` / `sim.toggle_fusion()`.
- If called on the **host** (or offline), they call the simulation methods directly — same function, dual code path via the `online and not hosting` branch check.
- This means **a guest can never illegally equip themselves as actor 0** or trigger an action for the wrong actor id — `change_loadout`/`robot_action`'s host-side handlers hardcode `id/actor index = 1` regardless of what the RPC call site might pass, tying every guest-originated action to their own P2 slot.

## 4. Pause Semantics Differ Online vs. Offline

- **Offline:** opening the menu (`Esc`/`B`) sets `app.paused = true`, and losing OS window focus also auto-pauses (`NOTIFICATION_APPLICATION_FOCUS_OUT`).
- **Online:** `menu.open()`'s pause line is `app.paused = app.playing and not app.online` — i.e. **pause is disabled while online**, by design (README: "Online não pausa ao abrir o menu"). Opening the menu client-side still submits an empty input (`submit_input.rpc_id(1, {})`) each frame so P2 stops moving without freezing the host's simulation for the other player.

## 5. Validation Coverage

- **Same-machine integration test** (`tools/test_network.ps1` + `main.gd`'s `--network-host-test`/`--network-client-test` flags): spawns 2 headless processes, host auto-starts a run and waits for a connection; client auto-joins `127.0.0.1` and drives P2 with a scripted input sequence (`move right for 150 frames, then a jump at frame 100`) via the `automated` flag. Asserts (via log grep in the PowerShell script) that the host saw movement (`MOVED=true`) and the client received at least one `NETWORK_SNAPSHOT` print, with zero engine `ERROR`/`WARNING` lines.
- **Not validated** (explicitly, per `README.md` and `docs/MVP_STATUS.md`): real internet play across separate networks/NAT, physical gamepad input over network, or any packet-loss/latency-injection scenario.

---

_Deep-dive generated by BMAD Method `document-project` workflow_
