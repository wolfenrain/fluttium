---
sidebar_position: 1
description: The different gesture actions.
---

# Gestures

Fluttium provides a set of actions that will allow you to execute certain gesture in your
application.

## Tapping

To tap on widgets in your application you can use the `tapOn` action. The full YAML syntax of this
action is as followed:

```yaml
- tapOn:
    text: 'Your Text' # An optional text regexp that is used to find a widget by semantic labels and visible text
```

The short-hand syntax for this action is:

```yaml
- tapOn: 'Your Text' # It will try to find by semantic labels and visible text
```

## Long press

:::info
This is not yet implemented.
:::

## Drag gestures

:::info
This is not yet implemented.
:::
