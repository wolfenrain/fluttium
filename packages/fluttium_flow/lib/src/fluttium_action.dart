enum FluttiumAction {
  expectVisible,
  expectNotVisible,
  tapOn,
  inputText,
  takeScreenshot;

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
      default:
        throw Exception('Unknown action: $action');
    }
  }
}
