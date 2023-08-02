# 0.1.2

- chore: updated `mason` dependency to v0.1.0-dev.50 ([#305](https://github.com/wolfenrain/fluttium/issues/305))
- chore: bump `fluttium_driver` to 0.1.3 ([#322](https://github.com/wolfenrain/fluttium/issues/322))
- chore: bump mocktail from 0.3.0 to 1.0.0 in /packages/fluttium_cli ([#318](https://github.com/wolfenrain/fluttium/issues/318))
- docs: update README ([#323](https://github.com/wolfenrain/fluttium/issues/323))

# 0.1.1

- fix: use last step that is done for storing files ([#267](https://github.com/wolfenrain/fluttium/issues/267))
- fix: adjust fluttium version constraints ([#269](https://github.com/wolfenrain/fluttium/issues/269))

# 0.1.0

- chore: bump dart version to 3.0.0 ([#250](https://github.com/wolfenrain/fluttium/issues/250))
- chore: bump versions ([#256](https://github.com/wolfenrain/fluttium/issues/256))
- feat: check if installed Flutter version is supported ([#247](https://github.com/wolfenrain/fluttium/issues/247))
- chore: bump `fluttium_driver` version ([#263](https://github.com/wolfenrain/fluttium/issues/263))
- fix: use correct `log_action` version in `fluttium.yaml` ([#264](https://github.com/wolfenrain/fluttium/issues/264))

# 0.1.0-dev.19

- chore: bump `pub_updater` from 0.2.4 to 0.3.0 in /packages/fluttium_cli ([#231](https://github.com/wolfenrain/fluttium/issues/231))
- fix: `expanded` reporter not storing screenshots ([#243](https://github.com/wolfenrain/fluttium/issues/243))

# 0.1.0-dev.18

- fix: always use given device instead of prompting ([#195](https://github.com/wolfenrain/fluttium/issues/195))
- feat: add shell completion ([#190](https://github.com/wolfenrain/fluttium/issues/190))
- feat: add support for different reporters ([#196](https://github.com/wolfenrain/fluttium/issues/196))
- chore: update `fluttium_driver` to v0.1.0-dev.3 ([#199](https://github.com/wolfenrain/fluttium/issues/199))

# 0.1.0-dev.17

- fix: driver configuration is not being read correctly from `fluttium.yaml` ([#182](https://github.com/wolfenrain/fluttium/issues/182))

# 0.1.0-dev.16

- feat: add support for custom actions ([#112](https://github.com/wolfenrain/fluttium/issues/112))

# 0.1.0-dev.15

- chore: update `fluttium_runner` to v0.1.0-dev.11 ([#110](https://github.com/wolfenrain/fluttium/issues/110))

# 0.1.0-dev.14

- fix: don't escape steps in flow brick ([#97](https://github.com/wolfenrain/fluttium/issues/97))
- feat: add `--dart-define` options to the CLI to pass to the Flutter process ([#96](https://github.com/wolfenrain/fluttium/issues/96))
- chore: update `fluttium_runner` to v0.1.0-dev.10 ([#101](https://github.com/wolfenrain/fluttium/issues/101))

# 0.1.0-dev.13

- refactor: properly use the semantic tree instead of relying on the `integration_test` framework ([#70](https://github.com/wolfenrain/fluttium/issues/70))
- chore: update `fluttium_runner` to v0.1.0-dev.9 ([#94](https://github.com/wolfenrain/fluttium/issues/94))

# 0.1.0-dev.12

- chore: update `fluttium_runner` to v0.1.0-dev.8 ([#90](https://github.com/wolfenrain/fluttium/issues/90))
- fix: use multi-line string to safely escape patterns for actions ([#88](https://github.com/wolfenrain/fluttium/issues/88))

# 0.1.0-dev.11

- feat: ensure only supported devices show up ([#81](https://github.com/wolfenrain/fluttium/issues/81))
- feat: support windows platform ([#82](https://github.com/wolfenrain/fluttium/issues/82))
- feat: support linux platform ([#79](https://github.com/wolfenrain/fluttium/issues/79))
- chore(fluttium_cli): update `fluttium_runner` to v0.1.0-dev.7 ([#84](https://github.com/wolfenrain/fluttium/issues/84))

# 0.1.0-dev.10

- fix: update prompt on update ([#72](https://github.com/wolfenrain/fluttium/issues/72))
- chore(fluttium_cli): update `fluttium_runner` to v0.1.0-dev.6 ([#77](https://github.com/wolfenrain/fluttium/issues/77))

# 0.1.0-dev.9

- fix: unexpected end of input error when running
- chore: update `fluttium_flow` to v0.1.0-dev.2
- chore: update `fluttium_runner` to v0.1.0-dev.5

# 0.1.0-dev.8

- fix: run flutter without version check
- refactor: use `Logger` instead of `print()` for CLI usage prompt

# 0.1.0-dev.7

- fix: sanitize text representations
- feat: support flavor and custom target file

# 0.1.0-dev.6

- chore: upgrade `fluttium_runner` to v0.1.0-dev.3

# 0.1.0-dev.5

- chore: upgrade `fluttium_runner` to v0.1.0-dev.2

# 0.1.0-dev.4

- fix: using wrong `packageVersion` in the version check

# 0.1.0-dev.3

- fix: using wrong `packageVersion` for the update command

# 0.1.0-dev.2

- chore: upgrade `mason` to `0.1.0-dev.34`

# 0.1.0-dev.1

- feat: initial release 🎉
