# Bundle all bricks for the packages.

correctMason=mason
if [[ "$OSTYPE" == "msys" ]]; then
    correctMason=mason.bat
fi

# Bundle all cli bricks.
$correctMason bundle -t dart bricks/fluttium_action -o packages/fluttium_cli/lib/src/bundles/
$correctMason bundle -t dart bricks/fluttium_flow -o packages/fluttium_cli/lib/src/bundles/
dart format --fix packages/fluttium_cli

# Bundle all driver bricks.
$correctMason bundle -t dart bricks/fluttium_launcher -o packages/fluttium_driver/lib/src/bundles/
$correctMason bundle -t dart bricks/fluttium_test_runner -o packages/fluttium_driver/lib/src/bundles/
dart format --fix packages/fluttium_driver
