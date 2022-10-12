---
sidebar_position: 2
---

# Writing Your First Flow Test

You can create a test file by writing a YAML file: 

```yaml
description: The description of your flow test
---
- tapOn: "The text or a semantic label on the screen"
```

Or you can use the `create` command, which is able to ?? (can we generate tests for someone based 
on where they click?)

```shell
# ✨ Magically create a new flow test file
fluttium create ??
```

For more information on actions that you can use in a flow test, see the 
[Action References](/docs/actions) documentation.