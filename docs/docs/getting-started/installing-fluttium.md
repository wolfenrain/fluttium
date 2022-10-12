---
sidebar_position: 1
---

# Installing Fluttium CLI

:::info 
In order to install Fluttium CLI you must have the Flutter SDK installed on your machine.
:::

We recommend installing the `fluttium_cli` from [pub.dev](https://pub.dev):

```shell
# 📦 Install from pub.dev
flutter pub global activate fluttium_cli
```

Once you have successfully installed the `fluttium_cli` you can verify that it works by running the
`fluttium` command in your terminal. You should see the following output:

```shell
Fluttium, the UI testing tool for Flutter.

Usage: fluttium <command> [arguments]

Global options:
-h, --help            Print this usage information.
-v, --version         Print the current version.
    --[no-]verbose    Noisy logging, including all shell commands executed.

Available commands: ...
```

For more information on the CLI, see the [Fluttium CLI](/docs/fluttium-cli) documentation.