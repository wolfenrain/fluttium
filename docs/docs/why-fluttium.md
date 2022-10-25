---
sidebar_position: 1
description: Fluttium focuses on the real user, the tests a developer writes with Fluttium are a direct representation of the actions that an user of an application would perform.
---

# Why Fluttium

There are quite a few app automation frameworks out there like [Appium](https://appium.io)
and [Maestro](https://maestro.mobile.dev), some are even dedicated to specific platforms, like
[UIAutomator](https://developer.android.com/training/testing/other-components/ui-automator) and
[XCTest](https://developer.apple.com/documentation/xctest). But they all have one thing in common,
their main focus is not the [Flutter](https://flutter.dev) ecosystem.

Thankfully the Flutter community has already created a beautiful set of tools to fill in the gap of
end-to-end testing in Flutter. Tools like [Patrol](https://patrol.leancode.co/) and
[Honey](https://github.com/clickup/honey) allow Flutter developers to easily write end-to-end tests
for their applications. But these tools have one thing in common, the tests written by a developer
does not have to directly reflect how a real user would use an application.

A user in the real world can navigate and use an application by seeing it with their own eyes or by
using a screen reader that reads the semantic labels that an application has defined. And that is
exactly where Fluttium comes into play.

Fluttium focuses on the real user, the tests a developer writes with Fluttium are a direct
representation of the actions that an user of an application would perform. Fluttium exposes a set
of actions that a developer can use to write a user flow test.

These user flow tests are powered by the semantic tree of the Flutter application, this allows
Fluttium to fully act like the real user and execution actions. Fluttium optimizes these actions as
well, for example by automatically waiting till an action is truly completed.

As a result, Fluttium does not support certain features that a Flutter developer would expect. For
instance, Fluttium does not provide an API to search by a
[Key](https://api.flutter.dev/flutter/foundation/Key-class.html). A real user of an application
would not be able to see or read a key, so why should the user flow test be aware of it.

Fluttium indirectly forces developers to think about the accessibility of their applications.
Adding self-defined semantic labels that makes sense for the action of a button or icon becomes the
norm when using Fluttium for user flow tests.

Out of the box Fluttium provides the following:

- Fluttium is able to monitor both your test file and your app code, so you can see your changes
  reflected in your tests immediately.
- Fluttium's syntax is designed to be as declarative as possible, allowing you to write tests
  that are easy to read and understand. Represented by a simple YAML file.
- Actions are only executed once your app settles. Fluttium uses the application's semantic tree
  under the hood and that allows it to wait until an action is completed.

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

## Supported Platforms

Fluttium supports all platforms that Flutter supports:

| Android | iOS | Web | macOS | Windows | Linux |
| ------- | --- | --- | ----- | ------- | ----- |
| ✅      | ✅  | ✅  | ✅    | ✅      | ✅    |

Fluttium can in theory supports any custom embedder for Flutter but this has not been tested
out yet.

## Other awesome Flutter testing tools

As mentioned in the intro, Fluttium is not the only tool in the Flutter ecosystem that tries to fill
in the gaps that Flutter has in the E2E space. So here is a list of other awesome open source
packages that, while having different goals, try to fill up those gaps:

- [Patrol](https://patrol.leancode.co/) by LeanCode
- [Honey](https://github.com/clickup/honey) by ClickUp
