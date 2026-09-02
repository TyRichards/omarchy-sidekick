# Sidekick Session Review

## Core plugin

- [x] Build an Omarchy 4 / Quickshell Sidekick bar plugin.
- [x] Toggle Sidekick with `SUPER + \\`.
- [x] Launch the configured Omarchy default agent.
- [x] Use Omarchy's default terminal through `xdg-terminal-exec`.
- [x] Support Foot, Ghostty, Kitty, and Alacritty without terminal-specific launch logic.
- [x] Support Web, Terminal, and official ChatGPT Desktop display preferences.
- [x] Add a Sidekick desktop launcher that opens settings.
- [x] Persist Sidekick preferences in `~/.config/omarchy/sidekick.json`.

## Settings modal

- [x] Match the Audio modal width, header sizing, typography, spacing, margins, and separator.
- [x] Use `` for Left and `` for Right in the bar and modal header.
- [x] Show `SUPER + \\` at the top-right of the modal header.
- [x] Rotate short uppercase Sidekick/hero Claudisms in the header, including the additional Oddjobb, Batman, and random-task phrases.
- [x] Move the Side Panel section directly below the header.
- [x] Order sections as Side Panel, Default Agent, Display Preference, Empty Terminal.
- [x] Show `DEFAULT AGENT · <AGENT>` above the default-agent button.
- [x] Dynamically label the button `Set Default Agent` or `Reset Default Agent`.
- [x] Use the Agents bar robot icon on the default-agent button.
- [x] Keep the default-agent button full width and centered.
- [x] Remove the separator below the default-agent button.
- [x] Add ` Left`, ` Right`, ` Web App`, and ` Terminal` controls.
- [x] Match Agents-provider button sizing and independent hover behavior.
- [x] Move `USE EMPTY TERMINAL` below Display Preference.
- [x] Render Empty Terminal as an Audio-style switch with a left-aligned section-title-colored label.
- [x] Gray and disable Default Agent and Display Preference while Empty Terminal is enabled.
- [x] Remove the top-bar icon tooltip.
- [x] Show an inline red unsupported-Web-App error.
- [x] Shake the complete modal card subtly twice for any invalid preference selection, moving inward from either left- or right-anchored placement.
- [x] Save display preference immediately and ask `Reset current Sidekick panel?` with compact Yes/No buttons.
- [x] Keep existing activity on No and reset/reopen the selected default experience on Yes.
- [x] Disable Hyprland cursor warping only while the settings modal is open.
- [x] Make first Escape close only the modal and second Escape collapse Sidekick.

## Panel geometry and bar integration

- [x] Support Left and Right slide-out placement.
- [x] Restore the final pane width to `floor(1400 / 3) = 466` logical pixels.
- [x] Keep Web App, Terminal, and Desktop consistent at the 466-unit target.
- [x] Place the pane flush against top or bottom bar bounds.
- [x] Preserve the visible top pane border below transparent and opaque top bars.
- [x] Expand and contract live when top or bottom bars are hidden or shown.
- [x] Synchronize bar-bound geometry with surrounding Hyprland panes without delayed follow-up.
- [x] Add a `Color.muted` strip equal to a same-side vertical bar's exact width.
- [x] Omit the strip when the vertical bar is on the opposite side.
- [x] Mirror same-side strip behavior between Left and Right bars.
- [x] Restore the normal Retro 82 / active-theme Hyprland border color and gradient.
- [x] Clear stale per-window border overrides from persistent Sidekick clients.
- [x] Keep Sidekick at normal global Hyprland/terminal transparency.

## Motion and interaction

- [x] Remove Sidekick-specific duration overrides and follow the active theme's `windowsMove` duration exactly.
- [x] Remove first-open overshoot and corrective movement.
- [x] Prevent all vertical motion during reveal and collapse.
- [x] Stage Left strictly off-screen left and Right strictly off-screen right.
- [x] Collapse on the current edge and reveal from the opposite edge when switching sides.
- [x] Never translate the open pane across the desktop during side changes.
- [x] Disable the geometry guardian before close motion to remove snap-back, strobe, and close stutter.
- [x] Restore focus to the most recently selected Hyprland pane after collapse or close.
- [x] Make `SUPER + W` collapse Sidekick instead of closing its terminal process.
- [x] Make Escape collapse Sidekick when the modal is not open.
- [x] Preserve normal `SUPER + W` behavior everywhere else.
- [x] Route the Sidekick hotkey directly to the plugin command to reduce launch latency.

## Geometry lock

- [x] Lock Sidekick to its computed size and position.
- [x] Suppress standard Omarchy `code:20` / `code:21` resize bindings while Sidekick is focused.
- [x] Prevent fullscreen and maximize state from sticking.
- [x] Keep Sidekick floating and pinned while visible.
- [x] Correct movement, workspace, resize, and float/tile mutations.
- [x] Avoid resize flashes and glitchy snap-back behavior.
- [x] Preserve live bar-driven height changes while geometry is locked.

## Web App reveal settlement

- [x] Publish visible guardian state only after the final reveal target is dispatched.
- [x] Accept Brave/Chromium and native ChatGPT's enforced 480-unit minimum while clipping excess beyond the selected edge.
- [x] Eliminate the final horizontal bounce caused by a post-animation width correction.

## Sidekick clipboard shortcuts

- [x] Make `SUPER+C/V` recognize exact Sidekick app-id windows as terminal clipboard surfaces.
- [x] Translate `CTRL+C/V` to terminal copy/paste only while Sidekick is active.
- [x] Preserve normal Ctrl+C/V behavior outside Sidekick.

## Agent and terminal behavior

- [x] Let each harness use its native exit command without a global Ctrl+D override.
- [x] Let Pi use native Ctrl+D without leaking EOF into the replacement shell.
- [x] Keep the terminal open as a bare login shell after an agent exits.
- [x] Open Empty Terminal in `~/Work`.
- [x] Show the persistent unavailable-TUI guidance message in a normal shell.
- [x] Detect missing or unsupported Omarchy TUI executables.
- [x] Map Claude to Claude Web, Codex to plain ChatGPT, Grok to Grok, Gemini to Gemini, and Copilot to GitHub Copilot.
- [x] Reject unsupported Web App selections without replacing current activity.
- [x] Open the unsupported-Web-App modal error when a saved Web preference becomes unavailable.
- [x] Keep default-agent changes non-destructive to active or persisted Sidekick activity.
- [x] Update the modal/future fallback immediately when Omarchy's default agent changes.
- [x] Track the last recognized harness manually launched inside Sidekick.
- [x] Track shell-only working-directory activity without rerunning arbitrary commands.
- [x] Resume Pi, Claude, Codex, and Grok through native latest-session continuation where available.
- [x] Reopen other recognized harnesses through their normal interactive command.
- [x] Restore a persisted shell in its last working directory with normal shell history.
- [x] Fall back to the Omarchy default only when no recoverable Sidekick activity exists.
- [x] Preserve manual non-default harness activity across normal close, restart, reboot, and recoverable crash state.

## Native Desktop map and settlement

- [x] Apply a temporary map-time rule that makes ChatGPT Desktop transparent, nonanimated, storage-workspace-bound, and 480px wide before its first frame.
- [x] Remove the temporary rule and restore full opacity only after the native class/window is settled off-screen.
- [x] Publish guardian visibility after the final reveal target so Desktop cannot bounce through a late correction.

## Display control order

- [x] Order and title the display controls exactly as Terminal, Web App, Desktop.
- [x] Keep keyboard navigation indexes aligned with the reordered controls.

## Reactive settings

- [x] Clicking Left or Right opens a closed Sidekick on that edge.
- [x] Clicking the opposite side while open performs close-animation then opposite-edge open-animation.
- [x] Clicking Web App or Terminal stores the preference without automatically destroying current activity.
- [x] Confirmed display reset closes/replaces/reopens the selected default experience.
- [x] Empty Terminal toggle immediately replaces the current client with a blank terminal.
- [x] Turning Empty Terminal off restores the selected agent experience.

## Validation and packaging

- [x] Add a plugin manifest, Sidekick SVG icon, README, MIT license, and test runner.
- [x] Validate the plugin with `omarchy-plugin-validate`.
- [x] Validate the generated desktop entry.
- [x] Validate runtime IPC and Hyprland reload recovery.
- [x] Validate top, bottom, left, and right bar geometry.
- [x] Validate modal layout and error-state screenshots.
- [x] Validate hidden and visible agent recovery flows.
- [x] Validate locked geometry and clean restoration of temporary compositor settings.

## Workspace-stable reveal

- [x] Derive reveal placement from the active window's monitor and workspace instead of potentially stale monitor history.
- [x] Reassert the invocation workspace before focusing a remapped Sidekick client.
- [x] Refuse to restore a stale focus address from a different workspace during delayed collapse or terminal cleanup.

## Bar-aware padding and top rule

- [x] Remove every horizontal and vertical bar-lane strip while preserving reserved bar lanes.
- [x] Ignore top/bottom bar bounds and extend the real pane four pixels beyond both screen edges so neither horizontal border is visible.
- [x] Keep the pane fixed at 466px and extend it beneath a same-side vertical bar.
- [x] Simulate asymmetric side padding with a nonanimated theme-background layer of the bar's exact width just inside the pane border.
- [x] Use the same nonanimated theme-background masking for top/bottom bars, matching their exact height across the full pane width.
- [x] Show exact-height top and bottom horizontal padding layers in Web App mode as well as Terminal/Desktop.
- [x] Keep dedicated left/right padding layers mapped and input-transparent, toggling only color to avoid reveal-time creation, dynamic anchor flips, and frame hitches.
- [x] Derive same-side icon-mask width from the exact moving pane/bar intersection so icons disappear under the leading edge and reappear only behind the trailing edge.
- [x] Hold top/bottom/side padding coverage through collapse, translate it by the full pane width with the exact pane duration/easing, and clear it only after both settle off-screen.
- [x] Keep the real top border four pixels above the screen in every bar configuration so it always overlaps off-screen.
- [x] Remove every top color band, horizontal strip, and line completely.
- [x] Set Sidekick compositor opacity to 100% before movement and keep it constant through reveal, collapse, and focus changes.

## Reset ownership safety

- [x] Resolve Sidekick ownership by its persisted address or exact app id, never by a stale tag alone.
- [x] Remove stale `sidekick` tags from unrelated browser windows without closing those windows.
- [x] Ensure Reset closes only the owned Sidekick client before relaunching it.

## Focus-sensitive border and navigation

- [x] Apply the live theme's explicit active border while Sidekick is hovered, focused, or receiving keyboard input.
- [x] Apply the live theme's separate explicit inactive border immediately when pointer and keyboard focus leave Sidekick.
- [x] Make inward `SUPER + LEFT/RIGHT` leave Sidekick focused on the adjacent saved workspace pane without collapsing it.
- [x] Make outward directional focus from the furthest regular pane enter the visible Sidekick pane on that edge.
- [x] Preserve normal directional Hyprland focus between regular panes before falling through to Sidekick.

## Native pane-move bindings

- [x] Make `SUPER + SHIFT + LEFT/RIGHT` change Sidekick's saved side while Sidekick is active.
- [x] Ignore the direction matching the current Sidekick edge and animate only an actual opposite-edge move.
- [x] Reuse the modal's collapse-current-edge then reveal-new-edge animation and synchronize its Left/Right buttons.
- [x] Preserve normal Hyprland window swapping when any non-Sidekick window is active.

## Monitor hotplug concealment

- [x] Immediately hide a visible Sidekick without animation when a monitor is added or removed.
- [x] Deduplicate exact Sidekick clients while hidden, wait for Hyprland topology settlement, and resize/restage against the focused display.
- [x] Never expose monitor-change resizing, pin correction, or preload placement.

## Monitor and workspace recovery

- [x] Diagnose the apparent workspace 6 duplicate as one pinned client restoring a stale per-workspace floating position after external-monitor disconnect.
- [x] Keep hidden preloads unpinned on a silent storage workspace so Hyprland cannot expose a stale workspace-specific position.
- [x] Move, resize, and restage the hidden preload atomically on workspace and monitor changes.
- [x] Reconcile duplicate Sidekick clients during setup, preserving the address recorded in active state and closing stale extras.

## Reset action

- [x] Move RESET into the modal header's top-right corner with the large circular-arrow icon on the right, using Wi-Fi QR action sizing/color.
- [x] Move `SUPER + \\` to the footer's bottom-right position on the Empty Terminal row.
- [x] Reset the current Sidekick experience without changing the saved side, display, default-agent, or Empty Terminal preferences.

## Hidden bar-bound geometry

- [x] Expand or contract the preloaded off-screen client immediately when a top or bottom bar hides or appears.
- [x] Keep hidden Y/height synchronized so reveal requires only horizontal movement and never corrects vertically after opening.

## Final modal and motion refinements

- [x] Advance to a fresh Claudism every time the settings modal opens.
- [x] Match the Default Agent heading-to-button margin to the other modal sections.
- [x] Remove the temporary 160ms custom profile after switching to exact theme inheritance.
- [x] Inherit the exact effective Omarchy/Hyprland `windowsMove` enabled state, speed, style, and Bezier curve for reveal, collapse, and padding layers, falling back through `windows` and `global`.
- [x] Remove redundant preparation, preference, default-agent, client, focus, geometry, and animation-profile work from the preloaded hotkey path.

## Preloaded edge behavior

- [x] Preload the selected Sidekick experience during shell setup instead of waiting for the first toggle.
- [x] Keep the hidden panel loaded and unpinned on Sidekick's silent storage workspace.
- [x] Reveal the existing surface without retaining any per-window opacity state.
- [x] Preserve the requested visible-width target when a native client enforces a larger minimum size.

## Previously deferred work completed

- [x] Research whether Grok Build can inherit the active terminal ANSI palette without inventing or maintaining a custom theme. Grok 1.0.5 documents named `[ui] theme` / `GROK_THEME` values but no ANSI or terminal-palette theme, so Sidekick correctly leaves the user's Grok theme untouched.
- [x] Add the official ChatGPT Linux desktop app as a third Sidekick display preference for Codex/ChatGPT defaults while retaining plain `https://chatgpt.com` for Web mode.
