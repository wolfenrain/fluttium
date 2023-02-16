# Setup local development for Fluttium.
#
# This is a one-time setup script.

echo "dependency_overrides:
  fluttium:
    path: $(pwd)/packages/fluttium
  fluttium_protocol:
    path: $(pwd)/packages/fluttium_protocol
  fluttium_interfaces:
    path: $(pwd)/packages/fluttium_interfaces" | tee example/pubspec_overrides.yaml > bricks/fluttium_test_runner/__brick__/pubspec_overrides.yaml