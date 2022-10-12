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

Or you can use the `create` command, which will generate a initial test file for you.

```shell
# 🖥 Create a test flow file
fluttium create my_flow.yaml --desc "The description of your flow test"
```

For more information on actions that you can use in a flow test, see the 
[Action References](/docs/actions) documentation.