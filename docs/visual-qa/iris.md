# Iris: browser-based visual QA (optional)

Iris is an external, optional visual inspection tool exposed to Codex through a project-scoped MCP server. It supplements—not replaces—Godot tests, human art direction, or the asset contract.

## What it is useful for

- Inspecting the game's **web export** in a real browser at multiple viewports.
- Returning screenshots and reporting browser-visible layout, contrast, clipping, console, frame-loop, and input issues.
- Reviewing web UI changes or checking that a browser-exported playable scene responds to input.

## What it does not prove

- It does not inspect Godot's native desktop renderer or source sprite files directly.
- A clean report is not proof of the 2:1 isometric grid, modular wall dimensions, sprite alpha, pivot/anchor, tile footprint, or visual similarity to approved art. Keep those as explicit image/engine QA checks and human review.
- Canvas-based content can be structurally invisible to DOM checks; inspect the returned screenshots as well as the report.
- Do not call a web-export inspection a native-runtime test.

## Project setup

The repository's `.codex/config.toml` registers `@tools-for-agents/iris` version `0.1.0` as a local stdio MCP server. It is pinned rather than floating. This workstation's Chrome path is supplied through `IRIS_CHROME` because Iris did not auto-detect the installed browser during validation. Change that environment value if Chrome is installed elsewhere. Codex loads project MCP configuration only after the repository is trusted; restart/reload Codex after trusting it, then confirm the Iris tools are listed before relying on them. Node.js 22 or newer and a supported browser (Chrome/Chromium/Edge/Brave) are required.

No global installation, game source changes, export preset, or generated asset is included by this integration. At the time this was added, `godot/export_presets.cfg` did not exist, so the game still needs an agreed Web export preset and export templates before an Iris game-loop test can run.

## Suggested use

1. Export a known test scene/build to a temporary location outside the canonical game source tree.
2. Serve the export locally over HTTP if its generated loader requires it.
3. Use `iris_look` to capture and inspect the actual page/screenshots.
4. Use `iris_play` only with explicit expected controls and a disposable test build.
5. Record the export commit/build, browser, viewport, controls, screenshots, and findings. Keep Iris results as supplementary evidence and do not mark a gameplay acceptance gate passed from Iris alone.

The MCP tool receives the target URL/path supplied at invocation. Use only project-owned, local test targets; do not point it at private or unrelated pages/files.

## Place in the Marea production council

**IRIS_VISUAL_QA** is a tool role, not an autonomous agent or approver:

- Work decides whether a browser-rendered visual check is relevant to a task.
- Jev may recommend Iris for browser-visible UI and game-loop evidence in shadow mode.
- Claude retains architecture review; Iris has no architectural authority.
- Graphify and Ponytail retain their dependency and scope-review roles.
- The visual worker and QA auditor retain responsibility for sprite contracts, alpha, anchors, tile footprints, the 2:1 grid, native Godot behavior, and final acceptance.

For each applicable task, record `IRIS_STATUS: RUN`, `NOT_REQUIRED + rationale`, or `BLOCKED + evidence`. Never claim native-Godot or asset-contract `PASS` based only on Iris. A run against the repository-root `index.html` is a web-prototype check, not evidence for the Godot game.
