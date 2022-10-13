<p align="center">
<img src="https://raw.githubusercontent.com/wolfenrain/fluttium/main/assets/fluttium_full.png" height="125" alt="fluttium logo" />
</p>

<p align="center">
<a href="https://github.com//wolfenrain/fluttium/actions"><img src="https://github.com//wolfenrain/fluttium/workflows/fluttium_cli/badge.svg" alt="fluttium_cli"></a>
<a href="https://github.com//wolfenrain/fluttium/actions"><img src="https://raw.githubusercontent.com/wolfenrain/fluttium/main/coverage_badge.svg" alt="coverage"></a>
<a href="https://pub.dev/packages/very_good_analysis"><img src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg" alt="style: very good analysis"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

Fluttium, the UI testing tool for Flutter.

![Fluttium Demo][fluttium_demo]

## Packages

| Package                                                                                        | Pub                                                                                                       |
| ---------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| [fluttium_cli](https://github.com/wolfenrain/fluttium/tree/master/packages/fluttium_cli)       | [![pub package](https://img.shields.io/pub/v/fluttium_cli.svg)](https://pub.dev/packages/fluttium_cli)    |
| [fluttium_flow](https://github.com/wolfenrain/fluttium/tree/master/packages/fluttium_flow)     | [![pub package](https://img.shields.io/pub/v/fluttium_cli.svg)](https://pub.dev/packages/fluttium_flow)   |
| [fluttium_runner](https://github.com/wolfenrain/fluttium/tree/master/packages/fluttium_runner) | [![pub package](https://img.shields.io/pub/v/fluttium_cli.svg)](https://pub.dev/packages/fluttium_runner) |

## Quick Start

```shell
# 📦 Install from pub.dev
flutter pub global activate fluttium_cli

# 🖥 Create a test flow file
fluttium create my_flow.yaml --desc "My cool flow"

# 🧪 Run a test flow file
fluttium test your_flow.yaml
```

## Documentation

View the full documentation [here](https://fluttium.dev/).

[fluttium_demo]: https://raw.githubusercontent.com/wolfenrain/fluttium/main/docs/static/img/hero.gif