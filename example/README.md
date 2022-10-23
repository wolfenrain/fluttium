# Example

![coverage][coverage_badge]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

An example project for Fluttium, used for testing.

---

## Getting Started 🚀

This project contains 3 flavors:

- development
- staging
- production

Flavors for this example only work on iOS, Android, Web and Windows.

To run the desired flavor either use the following commands:

```sh
# Development
$ fluttium test flows/<flow_to_test.yaml> --flavor development --target lib/main_development.dart

# Staging
$ fluttium test flows/<flow_to_test.yaml> --flavor staging --target lib/main_staging.dart

# Production
$ fluttium test flows/<flow_to_test.yaml> --flavor production --target lib/main_production.dart

# None (only works on Linux and macOS)
$ fluttium test flows/<flow_to_test.yaml>
```

---

## Running Tests 🧪

To run all unit and widget tests use the following command:

```sh
$ flutter test --coverage --test-randomize-ordering-seed random
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
$ genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
$ open coverage/index.html
```

[coverage_badge]: https://raw.githubusercontent.com/wolfenrain/fluttium/main/coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
