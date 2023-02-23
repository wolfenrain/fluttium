---
sidebar_position: 1
description: A set of actions to interact with your application.
---

# 🤝 Interactions

Fluttium provides a set of actions that will allow you to interact with your application as the user.

## Tapping/clicking

To tap or click on parts of the application you can use the `pressOn` action. This action will find
the item you want to click on and emit a pointer event to Fluter. The full YAML syntax of this
action is as followed:

```yaml
- pressOn:
    text: 'Your Text' # An optional text regexp that is used to find a widget by semantic labels and visible text
    offset: [10, 150] # An optional offset to tap somewhere on the screen.
```

The short-hand syntax for this action will assume you are using the text search:

```yaml
- pressOn: 'Your Text'
```

## Long press

To emit a long press to the application you can use the `longPressOn` action. The full YAML syntax
of this action is as follows:

```yaml
- longPressOn:
    text: 'Your Text' # An optional text regexp that is used to find a widget by semantic labels and visible text
    offset: [10, 150] # An optional offset to tap somewhere on the screen.
```

The short-hand syntax for this action will assume you are using the text search:

```yaml
- longPressOn: 'Your Text'
```

## Drag gestures

:::info
This is not yet implemented.
:::
