# Sidekick Development Instructions

- After every completed change batch, run `./test/all`, `git diff --check`, and `omarchy-plugin-validate .`.
- Fully recycle Sidekick after validation: close the owned client, restart Quickshell, run setup, preload/reveal the configured experience, and verify it is visible.
- Close every transient window created for testing before finishing.
- Create a local Git commit after every successfully validated change batch.
- Never include `.memory/` run artifacts in commits.
