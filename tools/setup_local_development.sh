# Setup local development for Fluttium.
#
# This is a one-time setup script.

localSetup="dependency_overrides:
  fluttium:
    path: $(pwd)/packages/fluttium
  fluttium_protocol:
    path: $(pwd)/packages/fluttium_protocol
  fluttium_interfaces:
    path: $(pwd)/packages/fluttium_interfaces"
    
echo "$localSetup" > example/pubspec_overrides.yaml 
echo "$localSetup" > bricks/fluttium_test_runner/__brick__/pubspec_overrides.yaml
echo "$localSetup" > actions/log_action/pubspec_overrides.yaml