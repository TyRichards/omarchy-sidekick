# Sidekick

A Quickshell plugin for Omarchy 4 that slides your default AI agent in from the left or right edge of the focused display.

- The floating panel uses the capped one-third width: `floor(1400 / 3) = 466` logical pixels on standard displays, consistently across every mode. Vertical bars reserve their own lane; Sidekick creates no top or side overlay strips.
- Reveal, collapse, and every attached padding layer inherit the exact effective Hyprland `windowsMove` profile from the current Omarchy theme—including enabled state, duration, style, and Bezier control points—with `windows`/`global` fallback when no explicit `windowsMove` override exists. The selected experience remains loaded and mapped on Sidekick's silent storage workspace while hidden. Reveal remaps the existing surface without mutating persistent opacity, prioritizing reliable visibility while still avoiding application startup. Bar-bound resizing starts immediately and uses the live Hyprland timing/easing so it stays synchronized with surrounding panes.
- The real Sidekick top edge always begins four pixels above the monitor, so its Hyprland top border stays off-screen. Sidekick creates no top color band, horizontal strip, or line. It is forced to 100% compositor opacity before movement begins and remains there throughout reveal/collapse. The bottom edge likewise extends four pixels beyond the monitor—even with a bottom bar—so the bottom border remains completely off-screen. Side bars are visually inside Sidekick's fixed 466px outer bounds using a nonanimated `Color.background` layer of the bar's exact width. Top and bottom bars use the same technique with a pane-width layer of the bar's exact height, except Web App mode intentionally omits the top-bar layer. Dedicated left- and right-anchored input-transparent layers stay mapped and merely change color, avoiding reveal-time surface creation, dynamic anchor flips, and frame hitches. A configured same-side vertical lane is masked by the exact geometric intersection of the moving pane and bar: icons disappear as the pane's leading edge crosses them and remain hidden until its trailing edge passes during collapse. Top, bottom, and side coverage remains opaque through collapse and translates with the pane using the exact inherited `windowsMove` duration and curve before clearing off-screen.
- Changing Left/Right collapses Sidekick into its current edge, then reveals it from the new edge instead of translating across the desktop.
- Monitor add/remove immediately parks Sidekick on its silent workspace without animation, deduplicates clients, waits for topology settlement, and resizes the hidden preload for the focused display—no intermediate geometry is exposed.
- Collapsing or closing Sidekick restores focus only to the most recently selected pane on the current workspace. Reveal captures and reasserts the invocation workspace before focusing Sidekick, preventing stale focus state from jumping back to a previously used workspace.
- `SUPER + \\` toggles the persistent agent panel.
- While Sidekick is focused, `SUPER + W` or `Esc` collapses it without ending the agent session; when the settings modal is open, the first `Esc` closes only the modal and a second `Esc` collapses Sidekick.
- Directional focus treats Sidekick as the outermost edge pane: moving right past the furthest regular pane enters a visible right-side Sidekick (mirrored on the left), and the inward key returns to the neighboring workspace pane without collapsing Sidekick. Normal movement between regular panes still wins first.
- While Sidekick is focused, the normal `SUPER + SHIFT + LEFT/RIGHT` window-swap bindings change its saved side instead: only the opposite edge acts, using the same collapse-then-reveal animation as the modal. Those bindings retain normal Hyprland swapping for every other window.
- TUI mode uses Omarchy's default terminal through `xdg-terminal-exec`, so Foot, Ghostty, Kitty, and Alacritty all work without terminal-specific configuration.
- Exiting a TUI agent with its normal quit command—including Pi's native `Ctrl+D`—leaves Sidekick open as a bare login shell. While Sidekick is focused, `SUPER+C/V` and `CTRL+C/V` translate to terminal copy/paste (`CTRL+Insert` / `SHIFT+Insert`); normal Ctrl+C/V behavior is preserved everywhere else.
- Sidekick records the last recognized harness and working directory. Normal restart or crash recovery resumes that harness's latest session where supported, or restores the shell directory/history without rerunning arbitrary commands.
- The pane is geometry-locked while visible: standard Hyprland resize bindings are suppressed, and move/fullscreen/float mutations are corrected immediately.
- Web App mode launches the official web destination for the selected Omarchy agent. Brave/Chromium's enforced 480-unit minimum is clipped beyond the selected edge, preventing a final-frame width correction.
- Clicking the bar icon opens a compact, Audio-width settings panel.
- A **Sidekick** desktop launcher opens the same settings panel from Omarchy's app menu.

## Install

```bash
omarchy plugin add https://github.com/TyRichards/omarchy-sidekick --enable
```

For local development:

```bash
omarchy dev link "$PWD"
```

Sidekick registers its runtime keybinding and window rule without modifying `~/.config/hypr/`. Runtime integrations are restored after a Hyprland config reload.

## Settings

Click the Sidekick bar icon to configure:

- **Side panel** — Left or Right.
- **Set / Reset Default Agent** — opens Omarchy's native Default Agent menu.
- **Display preference** — ordered Terminal, Web App, Desktop; saves the selected mode and asks before resetting current activity. Desktop uses the installed official ChatGPT Linux app for Codex/ChatGPT defaults.
- **Use Empty Terminal** — bypasses the agent and opens the default terminal in `~/Work`.

Preferences are stored in `~/.config/omarchy/sidekick.json`.

Web App destinations:

| Agent | Destination |
|---|---|
| ChatGPT | `chatgpt.com` |
| Claude Code | `claude.ai` |
| Codex | `chatgpt.com` |
| Gemini | `gemini.google.com` |
| Grok | `grok.com` |
| GitHub Copilot | `github.com/copilot` |

Pi, Oh My Pi, OpenCode, and Crush currently have no Sidekick Web App mapping. Selecting Web for one of them leaves the current activity untouched and shows an inline error.

Desktop mode requires the official `chatgpt` Linux app and a Codex or ChatGPT default. A temporary map-time rule makes the native client transparent, nonanimated, hidden, and fully sized before its first frame; the rule is removed before the normal Sidekick reveal. This prevents default-position flashes and final minimum-size corrections.

Grok Build exposes named built-in themes through `[ui] theme` and `GROK_THEME`, but its current documented settings do not expose an ANSI/default-terminal palette theme. Sidekick therefore leaves the user's Grok theme untouched rather than maintaining a custom approximation.

## Controls and IPC

```bash
omarchy-shell io.github.tyrichards.sidekick togglePanel
omarchy-shell io.github.tyrichards.sidekick collapsePanel
omarchy-shell io.github.tyrichards.sidekick openSettings
omarchy-shell io.github.tyrichards.sidekick closePanel
```

Left-click the bar icon for settings. Right-click it to toggle the agent panel.

If `SUPER + \\` is already assigned, Sidekick leaves the existing binding alone and sends a notification. You can bind Sidekick manually in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + BACKSLASH", "Sidekick", "omarchy-shell io.github.tyrichards.sidekick togglePanel")
```

## Development

```bash
./test/all
```

## License

MIT
