# MainRig Downstream Architecture

## Goal
Keep Desktop Commander upstream-compatible while making one Windows-hosted Remote Desktop Commander agent reliable for both native Windows work and WSL2 Ubuntu development.

## Non-goals
- Do not replace or reimplement the hosted Remote Desktop Commander relay.
- Do not change OAuth, Supabase/realtime transport, heartbeat, presence, or result delivery.
- Do not add ChatGPT-facing tool names until the hosted relay is proven to expose dynamic tools.
- Do not build a general workflow engine, agent framework, project database, or scheduler.
- Do not hard-code Living Town, GigaPunk, BuckshotUI, or user-specific paths into core logic.

## Compatibility boundary
Treat `src/remote-device/` as upstream-owned protocol code. Downstream changes there require a demonstrated compatibility bug and dedicated tests.
Treat existing MCP tool names, argument schemas, and result envelopes as public contracts.
Preserve stock behavior when MainRig extensions are disabled.

## Extension boundary
MainRig-specific behavior belongs under `src/mainrig/` and is called only from narrow existing extension points.
Initial configuration is opt-in through environment variables so no migration or config-schema redesign is required.
The first supported host profile is Windows plus WSL2 Ubuntu.

## Execution model
ChatGPT -> official hosted relay -> forked remote device -> local MCP server -> target environment.
Windows remains the device host because it can reach Windows applications, Windows files, UNC WSL paths, and `wsl.exe`.
Linux repo commands execute inside WSL through native Linux tools; Windows application commands execute natively.

## First extension
Add an opt-in execution-profile resolver behind the existing `start_process` path. Do not change the public schema.
The resolver may recognize conservative aliases such as `wsl` or `wsl:Ubuntu` in the existing `shell` string and translate them to a tested `wsl.exe` invocation.
All unspecified shells retain exact upstream behavior.
Filesystem tools continue to use normal Windows paths or `\\wsl.localhost\...` paths; no virtual filesystem layer is introduced.

## Safety and fallback
The official `npx @wonderwhy-er/desktop-commander@latest remote` invocation remains the known-good fallback.
Development runs use the checkout's local `dist/index.js`, which the existing remote-device integration already prefers.
Never test experimental process-routing changes by replacing the currently running official agent in place.

## Gates
1. Clean upstream build.
2. Record upstream test baseline on MainRig.
3. Unit-test every downstream resolver/path translation rule.
4. Run upstream suite and compare against baseline, allowing no new failures.
5. Run local Windows and WSL smoke tests.
6. Pair a development device separately and verify official ChatGPT relay compatibility.
7. Only then make the forked build the normal MainRig agent.

## Scope rule
Every downstream feature must solve a failure observed in real use. If stock Desktop Commander already performs the task reliably, do not add another abstraction for it.
