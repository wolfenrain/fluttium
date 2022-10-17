---
sidebar_position: 1
---

# Why Fluttium

While there are many app automation frameworks (Appium, Maestro, UIAutomator, XCTest) out there,
none of them provide full automation across all the platforms that Flutter supports. Fluttium on
the other hand is build on top of the tooling provided by the Flutter framework, it is able to
support any and all platforms that Flutter supports.

Out of the box Fluttium provides the following:

- Fluttium is able to monitor both your test file and your app code, so you can see your changes
  reflected in your tests immediately.
- Fluttium's syntax is designed to be as declarative as possible, allowing you to write tests
  that are easy to read and understand. Represented by a simple YAML file.
- Actions are only executed once your app settles. Fluttium uses the Flutter integration testing
  framework under the hood and that allows it to automatically wait until an action is completed.

## Example

An example for an application that allows you to search the weather in a specific city:

```yaml
description: Find the weather in Chicago
---
- tapOn: Search
- tapOn: City
- inputText: Chicago
- tapOn: Submit
- expectVisible: Chicago
```

## Quick Start

```shell
# 📦 Install from pub.dev
flutter pub global activate fluttium_cli

# 🖥 Create a test flow file
fluttium create my_flow.yaml --desc "My cool flow"

# 🧪 Run a test flow file
fluttium test your_flow.yaml
```

## Other awesome Flutter testing tools

Fluttium isn't the first, and hopefully not the last, tool made for making user flow test in Flutter
easier. So here is a list of other awesome open source packages that, while having different goals,
try to make these kind of tests easier in Flutter:

- [Patrol](https://patrol.leancode.co/) by LeanCode
- [Honey](https://github.com/clickup/honey) by ClickUp