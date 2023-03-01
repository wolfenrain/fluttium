# Contribution Guidelines

**Note:** If these contribution guidelines are not followed your issue or PR might be closed, so
please read these instructions carefully.

## Contribution types

### Bug Reports

- If you find a bug, please first report it using [GitHub issues].
  - First check if there is not already an issue for it; duplicated issues will be closed.

### Bug Fix

- If you'd like to submit a fix for a bug, please read the [How To](#how-to-contribute) for how to
   send a Pull Request.
- Indicate on the open issue that you are working on fixing the bug and the issue will be assigned
   to you.
- Write `Fixes #xxxx` in your PR text, where xxxx is the issue number (if there is one).
- Include a test that isolates the bug and verifies that it was fixed.

### New Features

- If you'd like to add a feature to the library that doesn't already exist, feel free to describe
   the feature in a new [GitHub issue].
- If you'd like to implement the new feature, please wait for feedback from the project maintainers
   before spending too much time writing the code. In some cases, enhancements may not align well
   with the project future development direction.
- Implement the code for the new feature and please read the [How To](#how-to-contribute).

### Documentation & Miscellaneous

- If you have suggestions for improvements to the documentation or examples (or something
   else), we would love to hear about it.
- As always first file a [GitHub issue].
- Implement the changes to the documentation, please read the [How To](#how-to-contribute).

## How To Contribute

### Requirements

For a contribution to be accepted:

- Format the code using `dart format .`;
- Lint the code with `flutter analyze .`;
- Check that all tests pass: `flutter test`;
- Documentation should always be updated or added (if applicable);
- Examples should always be updated or added (if applicable);
- Tests should always be updated or added (if applicable);
- The PR title should start with a [conventional commit] prefix (`feat:`, `fix:` etc).

If the contribution doesn't meet these criteria, a maintainer will discuss it with you on the issue
or PR. You can still continue to add more commits to the branch you have sent the Pull Request from
and it will be automatically reflected in the PR.

## Open an issue and fork the repository

- If it is a bigger change or a new feature, first of all
   [file a bug or feature report][GitHub issue], so that we can discuss what direction to follow.
- [Fork the project][fork guide] on GitHub.
- Clone the forked repository to your local development machine
   (e.g. `git clone git@github.com:<YOUR_GITHUB_USER>/fluttium.git`).

### Environment Setup

Fluttium requires a bit of setup to develop locally, thankfully we have simple shell script that
does all the heavy lifting for you:

```shell
cd tools && dart pub get && cd ..
dart tools/setup_local_environment.dart
```

After that you can install the local version of the CLI to test your changes:

```shell
dart pub global activate --source path ./packages/fluttium_cli
```

### Performing changes

- Create a new local branch from `main` (e.g. `git checkout -b my-new-feature`)
- Make your changes (try to split them up with one PR per feature/fix).
- When committing your changes, make sure that each commit message is clear
 (e.g. `git commit -m 'feat: implementing a Wait action'`).
- Push your new branch to your own fork into the same remote branch
 (e.g. `git push origin my-username.my-new-feature`, replace `origin` if you use another remote.)

**Note**: If you have changed any of the bricks you can run `./tools/bundle_all_bricks.sh` to update
them in the packages.

### Breaking changes

When doing breaking changes a deprecation tag should be added when possible and contain a message
that conveys to the user what which version that the deprecated method/field will be removed in and
what method they should use instead to perform the task. The version specified should be at least
two versions after the current one, such that there will be at least one stable release where the
users get to see the deprecation warning and in the version after that (or a later version) the
deprecated entity should be removed.

Example (if the current version is v1.3.0):

```dart
@Deprecated('Will be removed in v1.5.0, use nonDeprecatedFeature() instead')
void deprecatedFeature() {}
```

### Open a pull request

Go to the [pull request page of Fluttium][PRs] and in the top
of the page it will ask you if you want to open a pull request from your newly created branch.

The title of the pull request should start with a [conventional commit] type.

Allowed types are:

- `fix:` -- patches a bug and is not a new feature;
- `feat:` -- introduces a new feature;
- `docs:` -- updates or adds documentation or examples;
- `test:` -- updates or adds tests;
- `refactor:` -- refactors code but doesn't introduce any changes or additions to the public API;
- `perf:` -- code change that improves performance;
- `build:` -- code change that affects the build system or external dependencies;
- `ci:` -- changes to the CI configuration files and scripts;
- `chore:` -- other changes that don't modify source or test files;
- `revert:` -- reverts a previous commit.

If you introduce a **breaking change** the conventional commit type MUST end with an exclamation
mark (e.g. `feat!: removing the Wait action`).

Examples of PR titles:

- feat: implementing a `Wait` action
- fix: avoid infinite loop in `tester.find`
- docs: add an example for the `Wait` action
- test: add register test for the `Wait` action
- refactor: improving the driver starting time

[GitHub issue]: https://github.com/wolfenrain/fluttium/issues
[GitHub issues]: https://github.com/wolfenrain/fluttium/issues
[PRs]: https://github.com/wolfenrain/fluttium/pulls
[fork guide]: https://docs.github.com/en/get-started/quickstart/contributing-to-projects
[pubspec doc]: https://dart.dev/tools/pub/pubspec
[conventional commit]: https://www.conventionalcommits.org
