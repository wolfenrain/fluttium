---
sidebar_position: 2
description: The different expectation actions.
---

# Expectations

Fluttium provides a set of actions that will allow you to validate if certain widgets are
visible in your application.

## Visibility expectations

To check if a certain widget is visible or not you can use the `expectVisible` action. The full
YAML syntax of this action is as followed:

```yaml
- expectVisible:
    text: 'Your Text' # An optional text regexp that is used to find a widget by semantic labels and visible text
    key: 'Your Key' # An optional key that is used to find an widget that has the given key
```

The short-hand syntax for this action is:

```yaml
- expectVisible: 'Your Text or Key' # It will try to find by key first, if none is found it will try semantic labels and visible text
```

If you want to test if a certain widget is **not** visible you can use the `expectNotVisible` action.
It has the same syntax as the `expectVisible` action.
