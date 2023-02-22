---
sidebar_position: 4
---

# 🧪 Testing A Flow Test

Testing a flow can be done through the `fluttium test` command. This command will read the
`fluttium.yaml` file, apply any of the configuration it has to the driver and run the given flow
file.

```shell
fluttium test my_flow.yaml
```

The output of this command reflect the success state of the user flow, each step will be executed
and if one step fails it will stop executing steps and indicate which step failed with a potential
reason.

## Watching flow tests

Fluttium can also watch for any changes to either the flow file or the Flutter project, allowing
us to hot reload whenever changes are detected:

```shell
fluttium test my_flow.yaml --watch
```

The `fluttium test` command has options to override settings in the `fluttium.yaml` file, for the
full overview of options run:

```shell
fluttium test --help
```
