/// The action of a step.
enum FluttiumAction {
  /// Expect the given text or label to be visible.
  expectVisible,

  /// Expect the given text or label to not be visible.
  expectNotVisible,

  /// Tap on the given text or label or position.
  tapOn,

  /// Input the given text.
  inputText,

  /// Make a pause.
  wait,

  /// Take a screenshot with the given name.
  takeScreenshot;

  /// Resolve the given [name] to a [FluttiumAction].
  static FluttiumAction resolve(String action) {
    switch (action) {
      case 'expectVisible':
        return FluttiumAction.expectVisible;
      case 'expectNotVisible':
        return FluttiumAction.expectNotVisible;
      case 'tapOn':
        return FluttiumAction.tapOn;
      case 'inputText':
        return FluttiumAction.inputText;
      case 'takeScreenshot':
        return FluttiumAction.takeScreenshot;
      case 'wait':
        return FluttiumAction.wait;
      default:
        throw UnimplementedError('$action is not implemented');
    }
  }
}
