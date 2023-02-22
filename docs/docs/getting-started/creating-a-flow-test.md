---
sidebar_position: 3
---

# 🪄 Creating A Flow Test

We can use the `new flow` command to generate new flows for our project.

```shell
fluttium new flow <flow-name>
```

Once we run, `fluttium new flow my_flow`, we should see a `my_flow.yaml` that looks something like:

```yaml
description: My first Fluttium flow.
---
- log: 'Hello World!'
```

You can also pass extra options to the command to control the output, for the full overview of
options run:

```shell
fluttium new flow --help
```
