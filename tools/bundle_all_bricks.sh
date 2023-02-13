# Bundle all bricks for the packages.

# Bundle all cli bricks.
mason bundle -t dart bricks/fluttium_action -o packages/fluttium_cli/lib/src/bundles/
dart format --fix packages/fluttium_cli

# Bundle all driver bricks.
mason bundle -t dart bricks/fluttium_launcher -o packages/fluttium_driver/lib/src/bundles/
mason bundle -t dart bricks/fluttium_test_runner -o packages/fluttium_driver/lib/src/bundles/
dart format --fix packages/fluttium_driver