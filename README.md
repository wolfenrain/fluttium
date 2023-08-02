<p align="center">
<img src="https://raw.githubusercontent.com/wolfenrain/fluttium/main/assets/fluttium_full.png" height="125" alt="fluttium logo" />
</p>

<p align="center">
<a href="https://github.com//wolfenrain/fluttium/actions"><img src="https://github.com/wolfenrain/fluttium/actions/workflows/main.yaml/badge.svg" alt="ci"></a>
<a href="https://github.com//wolfenrain/fluttium/actions"><img src="https://raw.githubusercontent.com/wolfenrain/fluttium/main/coverage_badge.svg" alt="coverage"></a>
<a href="https://pub.dev/packages/very_good_analysis"><img src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg" alt="style: very good analysis"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
<a href="https://github.com/felangel/mason"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge" alt="Powered by Mason"></a>
</p>

---

Fluttium, the user flow testing tool for Flutter.

![Fluttium Demo][fluttium_demo]

## Packages

| Package                                                                                              | Pub                                                                                                                  |
|------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| [fluttium](https://github.com/wolfenrain/fluttium/tree/main/packages/fluttium)                       | [![pub package](https://img.shields.io/pub/v/fluttium.svg)](https://pub.dev/packages/fluttium)                       |
| [fluttium_cli](https://github.com/wolfenrain/fluttium/tree/main/packages/fluttium_cli)               | [![pub package](https://img.shields.io/pub/v/fluttium_cli.svg)](https://pub.dev/packages/fluttium_cli)               |
| [fluttium_driver](https://github.com/wolfenrain/fluttium/tree/main/packages/fluttium_driver)         | [![pub package](https://img.shields.io/pub/v/fluttium_driver.svg)](https://pub.dev/packages/fluttium_driver)         |
| [fluttium_interfaces](https://github.com/wolfenrain/fluttium/tree/main/packages/fluttium_interfaces) | [![pub package](https://img.shields.io/pub/v/fluttium_interfaces.svg)](https://pub.dev/packages/fluttium_interfaces) |
| [fluttium_protocol](https://github.com/wolfenrain/fluttium/tree/main/packages/fluttium_protocol)     | [![pub package](https://img.shields.io/pub/v/fluttium_protocol.svg)](https://pub.dev/packages/fluttium_protocol)     |

## Actions

| Action                                                                            | Pub                                                                                                |
|-----------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| [log_action](https://github.com/wolfenrain/fluttium/tree/main/actions/log_action) | [![pub package](https://img.shields.io/pub/v/log_action.svg)](https://pub.dev/packages/log_action) |

## Quick Start

```shell
# 📦 Install from pub.dev
flutter pub global activate fluttium_cli

# 🖥 Create a test flow file
fluttium new flow my_flow --description "My cool flow"

# 🧪 Run a test flow file
fluttium test my_flow.yaml
```

## Documentation

View the full documentation [here](https://fluttium.dev/).

## Examples

The [example](https://github.com/wolfenrain/fluttium/tree/main/example) directory contains 
[example user flows](https://github.com/wolfenrain/fluttium/tree/main/example/flows) that are
written for the example application.

These tests are used for testing of new features and will be kept up to date.

[fluttium_demo]: https://raw.githubusercontent.com/wolfenrain/fluttium/main/docs/static/img/hero.gif

## Contributing

Have you found a bug or have a suggestion of how to enhance Fluttium? Open an issue and we will 
take a look at it as soon as possible.

Do you want to contribute with a PR? PRs are always welcome, just make sure to create it from the
correct branch (main) and follow the [checklist](.github/pull_request_template.md) which will
appear when you open the PR.
