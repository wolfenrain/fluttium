---
sidebar_position: 2
description: A set of actions to validate certain aspect of your application.
---

# 💭 Expectations

Fluttium provides a set of actions that will allow you to validate if certain aspects of your
application are visible.

## Visibility expectations

To check if a specific text is visible (through a semantic value or not), you can use the
`expectVisible` action. This action goes through the semantic tree and checks semantic labels,
tooltips, text nodes, and other values to determine if something with the given text is visible.

By default it will timeout after 10 seconds of searching.

The full YAML syntax of this action is as followed:

```yaml
- expectVisible:
    text: 'Your Text' # An optional text regexp that is used to find a widget by semantic labels and visible text
    timeout: 100 # An optional timeout value, in milliseconds
```

The short-hand syntax for this action is:

```yaml
- expectVisible: 'Your Text' # It will try to find by semantic labels and visible text
```

If you want to test if a specific text is **not** visible you can use the `expectNotVisible` action.
It has the same syntax as the `expectVisible` action.
