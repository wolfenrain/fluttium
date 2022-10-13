---
sidebar_position: 1
description: The Fluttium test command.
---

# Test command

The `test` command is the core of the Fluttium CLI, it allows you to run your flow tests directly
on your devices. 

## Usage

```shell
# Test the given flow, will ask on which device to run it on.
fluttium test your_flow.yaml

# Test the given flow on the macOS desktop platform, if available.
fluttium test your_flow.yaml -d macos

# Test the given flow while watching both the flow and application code.
fluttium test your_flow.yaml --watch
```
