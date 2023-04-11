---
sidebar_position: 4
description: A set of actions that will allow you to debug your flow and your application.
---

# 🪲 Debugging

Fluttium provides a set of actions that will allow you to debug your flow and your application.

## Taking screenshots

Taking screenshots can be done through the `takeScreenshot` action. This action takes a full screenshot and stores it in a file of your choosing.

The full YAML syntax of this action is as followed:

```yaml
- takeScreenshot:
    path: 'path/to/screenshot.png'
    pixelRatio: 1.5 # Defaults to device pixel ration.
```

The short-hand syntax for this action is:

```yaml
- takeScreenshot: 'path/to/screenshot.png'
```
