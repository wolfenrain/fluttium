---
sidebar_position: 3
description: A set of actions to handle text manipulation within your application.
---

# ✍️ Text

Fluttium provides a set of actions that will allow you to handle text manipulation within your
application.

## Writing text

Writing text can be done through the `writeText` action. This action appends the given string to
whatever the current text value is as a user.

The full YAML syntax of this action is as followed:

```yaml
- writeText: "Your Text"
```

## Clearing text

You can also clear the current text value by using the `clearText` action. This actions clear the
text as a user would, by deleting the text character by character.

The full YAML syntax of this action is as followed:

```yaml
- clearText:
    characters: 100 # Optional amount of characters to clear, by default this will clear all.
```

The short-hand syntax for this action, which will clear all text:

```yaml
- clearText:
```