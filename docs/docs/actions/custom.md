---
sidebar_position: 2
---

# 🎨 Custom Actions

Fluttium supports custom actions, that you can install to be used in your user flows. 

Actions are defined as Dart packages, they can be published to [pub.dev](https://pub.dev) and have their own dependencies.

You can add custom actions by adding them to the `actions` section in your `fluttium.yaml`:

```yaml
actions:
  log_action: 0.1.0+1
```

Fluttium will automatically install this action from [pub.dev](https://pub.dev) when testing.

You can also add actions from GIT or from your local filesystem:

```yaml
actions:
  # From GIT:
  log_action:
    git:
      url: https://github.com/wolfenrain/fluttium.git
      path: actions/log_action
  # Or from path:
  log_action:
    path: ../path/to/log_action
```

## Creating a new action

We can use the `new action` command to generate a custom action.

```shell
fluttium new action <action-name>
```

Once we run, `fluttium new create my_action`, we should see a `my_action` directory whose structure should look something like:

```
my_action/
├── lib/
│   ├── src/
│   │   └── my_action.dart
│   └── my_action.dart
├── test/
│   ├── src/
│   │   └── my_action_test.dart
│   └── register_test.dart
├── .gitignore
├── analysis_options.yaml
├── CHANGELOG.md
├── LICENSE
├── pubspec.yaml
└── README.md
```

You can also pass extra options to the command to control the output, for the full overview of 
options run:

```shell
fluttium new action --help
```

## Finding published actions

You can find actions for Fluttium that have been published by using [the dependency search from pub.dev](https://pub.dev/packages?q=dependency%3Afluttium)