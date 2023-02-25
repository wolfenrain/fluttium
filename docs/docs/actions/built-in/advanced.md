---
sidebar_position: 5
description: A set of actions that will allow you to debug your flow and your application.
---

# 🧠 Advanced

Fluttium provides a set of actions that will allow you to debug your flow and your application.

## Wait

:::info
The `wait` action should only be used as a last resort. Fluttium exposes actions that help with
waiting for elements to be visible and those should be used instead if that is your goal.
:::

Sometimes it can be useful to be able to wait for a certain amount of time, for instance when you
want to wait until an audio fragment is done playing. For this Fluttium introduces the `wait`
action. This action will wait for a certain amount of time before moving on to the next step.

The full YAML syntax of this action is as followed:

```yaml
- wait:
    days: 1 # why would you do this?
    hours: 1
    minutes: 2
    seconds: 50
    milliseconds: 500
    microseconds: 50
```

The short-hand syntax for this action is:

```yaml
- wait: 500 # By default it uses milliseconds
```
