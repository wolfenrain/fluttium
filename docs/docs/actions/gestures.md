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
    key: 'Your Key' # An optional key that is used to find an widget that has the given key
```

The short-hand syntax for this action is:

```yaml
- tapOn: 'Your Text or Key' # It will try to find by key first, if none is found it will try semantic labels and visible text
```

## Long press

To do a long press on widgets in your application you can use the `longPressOn` action. The full 
YAML syntax of this action is as followed:

```yaml
- longPressOn:
    text: 'Your Text' # An optional text regexp that is used to find a widget by semantic labels and visible text
    key: 'Your Key' # An optional key that is used to find an widget that has the given key
```

The short-hand syntax for this action is:

```yaml
- longPressOn: 'Your Text or Key' # It will try to find by key first, if none is found it will try semantic labels and visible text
```

## Drag gestures

:::info
This is not yet implemented.
:::
