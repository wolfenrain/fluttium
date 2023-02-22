---
sidebar_position: 2
---

# 📁 Initializing Fluttium

Once `fluttium_cli` is installed, we can use the `init` command to initialize Fluttium in the
current project. This command will generate a `fluttium.yaml` in the current directory. This allow
you to install custom actions and configure the Fluttium driver.

```shell
fluttium init
```

Once we run, `fluttium init`, we should have a `fluttium.yaml` that looks like:

```yaml
# The following defines the environment for your Fluttium project. It includes 
# the version of Fluttium that the project requires.
environment:
  fluttium: ">=0.1.0-dev.1 <0.1.0"

# The driver can be configured with default values. Uncomment the following 
# lines to automatically run Fluttium using a different flavor and dart-defines.
# driver:
#   flavor: development
#   dartDefines:
#     - CUSTOM_DART_DEFINE=1

# Register actions which can be used within your Fluttium flows.
actions:
  # The following adds the log action to your project.
  log_action: 0.1.0+1
  # Actions can also be imported via git url.
  # Uncomment the following lines to import
  # the log_action from a remote git url.
  # log_action:
  #   git:
  #     url: https://github.com/wolfenrain/fluttium.git
  #     path: actions/log_action
```
