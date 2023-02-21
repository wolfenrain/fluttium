import 'dart:async';
import 'dart:io' if (kIsWeb) '';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Action;
import 'package:fluttium/fluttium.dart';
import 'package:fluttium_interfaces/fluttium_interfaces.dart';
import 'package:fluttium_protocol/fluttium_protocol.dart';

/// {@template tester}
/// The tester that is used to execute the actions in a flow file.
/// {@endtemplate}
class Tester {
  /// {@macro tester}
  Tester(this._binding, this._registry, {Emitter? emitter})
      : _emitter = emitter ?? Emitter();

  final Emitter _emitter;

  final WidgetsBinding _binding;

  final Registry _registry;

  SemanticsOwner get _semanticsOwner => _binding.pipelineOwner.semanticsOwner!;

  /// Converts the [steps] into a list of executable actions.
  Future<List<Future<void> Function()>> convert(
    List<UserFlowStep> steps,
  ) async {
    return Future.wait(
      steps.map((step) async {
        try {
          final action = _registry.getAction(step.actionName, step.arguments);
          final actionRepresentation = action.description();
          await _emitter.announce(actionRepresentation);

          return () async {
            try {
              await _emitter.start(actionRepresentation);
              if (await action.execute(this)) {
                return _emitter.done(actionRepresentation);
              }
              return _emitter.fail(actionRepresentation);
            } catch (err) {
              return _emitter.fail(actionRepresentation, reason: '$err');
            }
          };
        } catch (err) {
          await _emitter.fatal('$err');
          rethrow;
        }
      }).toList(),
    );
  }

  /// Store binary data with the given [fileName].
  Future<void> storeFile(String fileName, Uint8List bytes) async {
    await _emitter.store(fileName, bytes);
  }

  /// Dispatch an event to the targets found by a hit test on its position.
  void emitPointerEvent(PointerEvent event) {
    return _binding.handlePointerEvent(event);
  }

  /// Dispatch an event on the keyboard.
  Future<bool> emitKeyEvent(KeyEvent event) async {
    final result = _binding.keyEventManager.handleKeyData(
      KeyData(
        timeStamp: event.timeStamp,
        type: event is KeyDownEvent ? KeyEventType.down : KeyEventType.up,
        physical: event.physicalKey.usbHidUsage,
        logical: event.logicalKey.keyId,
        character: event.character,
        synthesized: event.synthesized,
      ),
    );

    final data = await emitPlatformMessage(
      SystemChannels.keyEvent.name,
      SystemChannels.keyEvent.codec.encodeMessage(
        getKeyData(
          event.logicalKey,
          isDown: event is KeyDownEvent,
          platform: kIsWeb ? 'web' : Platform.operatingSystem,
          physicalKey: event.physicalKey,
          character: event.character,
        ),
      ),
    );

    if (data == null) {
      return false;
    }
    final Map<String, Object?> decoded = SystemChannels.keyEvent.codec
        .decodeMessage(data)! as Map<String, dynamic>;
    return decoded['handled']! as bool || result;
  }

  // Look up a synonym key, and just return the left version of it.
  static LogicalKeyboardKey _getKeySynonym(LogicalKeyboardKey origKey) {
    if (origKey == LogicalKeyboardKey.shift) {
      return LogicalKeyboardKey.shiftLeft;
    }
    if (origKey == LogicalKeyboardKey.alt) {
      return LogicalKeyboardKey.altLeft;
    }
    if (origKey == LogicalKeyboardKey.meta) {
      return LogicalKeyboardKey.metaLeft;
    }
    if (origKey == LogicalKeyboardKey.control) {
      return LogicalKeyboardKey.controlLeft;
    }
    return origKey;
  }

  static PhysicalKeyboardKey _findPhysicalKeyByPlatform(
    LogicalKeyboardKey key,
    String platform,
  ) {
    late Map<dynamic, PhysicalKeyboardKey> map;
    if (kIsWeb) {
      // This check is used to treeshake keymap code.
      map = kWebToPhysicalKey;
    } else {
      switch (platform) {
        case 'android':
          map = kAndroidToPhysicalKey;
          break;
        case 'fuchsia':
          map = kFuchsiaToPhysicalKey;
          break;
        case 'macos':
          map = kMacOsToPhysicalKey;
          break;
        case 'ios':
          map = kIosToPhysicalKey;
          break;
        case 'linux':
          map = kLinuxToPhysicalKey;
          break;
        case 'web':
          map = kWebToPhysicalKey;
          break;
        case 'windows':
          map = kWindowsToPhysicalKey;
          break;
      }
    }
    PhysicalKeyboardKey? result;
    for (final physicalKey in map.values) {
      if (key.debugName == physicalKey.debugName) {
        result = physicalKey;
        break;
      }
    }
    assert(
      result != null,
      'Physical key for $key not found in $platform physical key map',
    );
    return result!;
  }

  static String? _keyLabel(LogicalKeyboardKey key) {
    final keyLabel = key.keyLabel;
    if (keyLabel.length == 1) {
      return keyLabel.toLowerCase();
    }
    return null;
  }

  static int _getKeyCode(LogicalKeyboardKey key, String platform) {
    if (kIsWeb) {
      // web doesn't have int type code. This check is used to treeshake
      // keyboard map code.
      return -1;
    } else {
      late Map<int, LogicalKeyboardKey> map;
      switch (platform) {
        case 'android':
          map = kAndroidToLogicalKey;
          break;
        case 'fuchsia':
          map = kFuchsiaToLogicalKey;
          break;
        case 'macos':
          // macOS doesn't do key codes, just scan codes.
          return -1;
        case 'ios':
          // iOS doesn't do key codes, just scan codes.
          return -1;
        case 'web':
          // web doesn't have int type code.
          return -1;
        case 'linux':
          map = kGlfwToLogicalKey;
          break;
        case 'windows':
          map = kWindowsToLogicalKey;
          break;
      }
      int? keyCode;
      for (final code in map.keys) {
        if (key.keyId == map[code]!.keyId) {
          keyCode = code;
          break;
        }
      }
      assert(keyCode != null, 'Key $key not found in $platform keyCode map');
      return keyCode!;
    }
  }

  static int _getScanCode(PhysicalKeyboardKey key, String platform) {
    late Map<int, PhysicalKeyboardKey> map;
    switch (platform) {
      case 'android':
        map = kAndroidToPhysicalKey;
        break;
      case 'fuchsia':
        map = kFuchsiaToPhysicalKey;
        break;
      case 'macos':
        map = kMacOsToPhysicalKey;
        break;
      case 'ios':
        map = kIosToPhysicalKey;
        break;
      case 'linux':
        map = kLinuxToPhysicalKey;
        break;
      case 'windows':
        map = kWindowsToPhysicalKey;
        break;
      case 'web':
        // web doesn't have int type code
        return -1;
    }
    int? scanCode;
    for (final code in map.keys) {
      if (key.usbHidUsage == map[code]!.usbHidUsage) {
        scanCode = code;
        break;
      }
    }
    assert(
      scanCode != null,
      'Physical key for $key not found in $platform scanCode map',
    );
    return scanCode!;
  }

  static _WebKeyLocationPair _getWebKeyLocation(
    LogicalKeyboardKey key,
    String keyLabel,
  ) {
    String? result;
    for (final entry in kWebLocationMap.entries) {
      final foundIndex = entry.value.lastIndexOf(key);
      // If foundIndex is -1, then the key is not defined in kWebLocationMap.
      // If foundIndex is 0, then the key is in the standard part of the keyboard,
      // but we have to check `keyLabel` to see if it's remapped or modified.
      if (foundIndex != -1 && foundIndex != 0) {
        return _WebKeyLocationPair(entry.key, foundIndex);
      }
    }
    if (keyLabel.isNotEmpty) {
      return _WebKeyLocationPair(keyLabel, 0);
    }
    for (final code in kWebToLogicalKey.keys) {
      if (key.keyId == kWebToLogicalKey[code]!.keyId) {
        result = code;
        break;
      }
    }
    assert(result != null, 'Key $key not found in web keyCode map');
    return _WebKeyLocationPair(result!, 0);
  }

  static PhysicalKeyboardKey _inferPhysicalKey(LogicalKeyboardKey key) {
    PhysicalKeyboardKey? result;
    for (final physicalKey in PhysicalKeyboardKey.knownPhysicalKeys) {
      if (physicalKey.debugName == key.debugName) {
        result = physicalKey;
        break;
      }
    }
    assert(result != null, 'Unable to infer physical key for $key');
    return result!;
  }

  static String _getWebCode(PhysicalKeyboardKey key) {
    String? result;
    for (final entry in kWebToPhysicalKey.entries) {
      if (entry.value.usbHidUsage == key.usbHidUsage) {
        result = entry.key;
        break;
      }
    }
    assert(result != null, 'Key $key not found in web code map');
    return result!;
  }

  /// Get a raw key data map given a [LogicalKeyboardKey] and a platform.
  static Map<String, dynamic> getKeyData(
    LogicalKeyboardKey key, {
    required String platform,
    bool isDown = true,
    PhysicalKeyboardKey? physicalKey,
    String? character,
  }) {
    key = _getKeySynonym(key);

    // Find a suitable physical key if none was supplied.
    physicalKey ??= _findPhysicalKeyByPlatform(key, platform);

    final result = <String, dynamic>{
      'type': isDown ? 'keydown' : 'keyup',
      'keymap': platform,
    };

    final resultCharacter = character ?? _keyLabel(key) ?? '';
    void assignWeb() {
      final keyLocation = _getWebKeyLocation(key, resultCharacter);
      final actualPhysicalKey = physicalKey ?? _inferPhysicalKey(key);
      result['code'] = _getWebCode(actualPhysicalKey);
      result['key'] = keyLocation.key;
      result['location'] = keyLocation.location;
      result['metaState'] = _getWebModifierFlags(key, isDown);
    }

    if (kIsWeb) {
      assignWeb();
      return result;
    }
    final keyCode = _getKeyCode(key, platform);
    final scanCode = _getScanCode(physicalKey, platform);

    switch (platform) {
      case 'android':
        result['keyCode'] = keyCode;
        if (resultCharacter.isNotEmpty) {
          result['codePoint'] = resultCharacter.codeUnitAt(0);
          result['character'] = resultCharacter;
        }
        result['scanCode'] = scanCode;
        result['metaState'] = _getAndroidModifierFlags(key, isDown);
        break;
      case 'fuchsia':
        result['hidUsage'] = physicalKey.usbHidUsage;
        if (resultCharacter.isNotEmpty) {
          result['codePoint'] = resultCharacter.codeUnitAt(0);
        }
        result['modifiers'] = _getFuchsiaModifierFlags(key, isDown);
        break;
      case 'linux':
        result['toolkit'] = 'glfw';
        result['keyCode'] = keyCode;
        result['scanCode'] = scanCode;
        result['modifiers'] = _getGlfwModifierFlags(key, isDown);
        result['unicodeScalarValues'] =
            resultCharacter.isNotEmpty ? resultCharacter.codeUnitAt(0) : 0;
        break;
      case 'macos':
        result['keyCode'] = scanCode;
        if (resultCharacter.isNotEmpty) {
          result['characters'] = resultCharacter;
          result['charactersIgnoringModifiers'] = resultCharacter;
        }
        result['modifiers'] = _getMacOsModifierFlags(key, isDown);
        break;
      case 'ios':
        result['keyCode'] = scanCode;
        result['characters'] = resultCharacter;
        result['charactersIgnoringModifiers'] = resultCharacter;
        result['modifiers'] = _getIOSModifierFlags(key, isDown);
        break;
      case 'windows':
        result['keyCode'] = keyCode;
        result['scanCode'] = scanCode;
        if (resultCharacter.isNotEmpty) {
          result['characterCodePoint'] = resultCharacter.codeUnitAt(0);
        }
        result['modifiers'] = _getWindowsModifierFlags(key, isDown);
        break;
      case 'web':
        assignWeb();
        break;
    }
    return result;
  }

  static int _getAndroidModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    var result = 0;
    final pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataAndroid.modifierLeftShift |
          RawKeyEventDataAndroid.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataAndroid.modifierRightShift |
          RawKeyEventDataAndroid.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataAndroid.modifierLeftMeta |
          RawKeyEventDataAndroid.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataAndroid.modifierRightMeta |
          RawKeyEventDataAndroid.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataAndroid.modifierLeftControl |
          RawKeyEventDataAndroid.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataAndroid.modifierRightControl |
          RawKeyEventDataAndroid.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataAndroid.modifierLeftAlt |
          RawKeyEventDataAndroid.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataAndroid.modifierRightAlt |
          RawKeyEventDataAndroid.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.fn)) {
      result |= RawKeyEventDataAndroid.modifierFunction;
    }
    if (pressed.contains(LogicalKeyboardKey.scrollLock)) {
      result |= RawKeyEventDataAndroid.modifierScrollLock;
    }
    if (pressed.contains(LogicalKeyboardKey.numLock)) {
      result |= RawKeyEventDataAndroid.modifierNumLock;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataAndroid.modifierCapsLock;
    }
    return result;
  }

  static int _getGlfwModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    var result = 0;
    final pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= GLFWKeyHelper.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= GLFWKeyHelper.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= GLFWKeyHelper.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft) ||
        pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= GLFWKeyHelper.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= GLFWKeyHelper.modifierCapsLock;
    }
    return result;
  }

  static int _getWindowsModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    var result = 0;
    final pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shift)) {
      result |= RawKeyEventDataWindows.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataWindows.modifierLeftShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataWindows.modifierRightShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataWindows.modifierLeftMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataWindows.modifierRightMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.control)) {
      result |= RawKeyEventDataWindows.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataWindows.modifierLeftControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataWindows.modifierRightControl;
    }
    if (pressed.contains(LogicalKeyboardKey.alt)) {
      result |= RawKeyEventDataWindows.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataWindows.modifierLeftAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataWindows.modifierRightAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataWindows.modifierCaps;
    }
    if (pressed.contains(LogicalKeyboardKey.numLock)) {
      result |= RawKeyEventDataWindows.modifierNumLock;
    }
    if (pressed.contains(LogicalKeyboardKey.scrollLock)) {
      result |= RawKeyEventDataWindows.modifierScrollLock;
    }
    return result;
  }

  static int _getFuchsiaModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    var result = 0;
    final pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataFuchsia.modifierLeftShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataFuchsia.modifierRightShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataFuchsia.modifierLeftMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataFuchsia.modifierRightMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataFuchsia.modifierLeftControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataFuchsia.modifierRightControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataFuchsia.modifierLeftAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataFuchsia.modifierRightAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataFuchsia.modifierCapsLock;
    }
    return result;
  }

  static int _getWebModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    var result = 0;
    final pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataWeb.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataWeb.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataWeb.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataWeb.modifierMeta;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataWeb.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataWeb.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataWeb.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataWeb.modifierAlt;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataWeb.modifierCapsLock;
    }
    if (pressed.contains(LogicalKeyboardKey.numLock)) {
      result |= RawKeyEventDataWeb.modifierNumLock;
    }
    if (pressed.contains(LogicalKeyboardKey.scrollLock)) {
      result |= RawKeyEventDataWeb.modifierScrollLock;
    }
    return result;
  }

  static int _getMacOsModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    var result = 0;
    final pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataMacOs.modifierLeftShift |
          RawKeyEventDataMacOs.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataMacOs.modifierRightShift |
          RawKeyEventDataMacOs.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataMacOs.modifierLeftCommand |
          RawKeyEventDataMacOs.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataMacOs.modifierRightCommand |
          RawKeyEventDataMacOs.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataMacOs.modifierLeftControl |
          RawKeyEventDataMacOs.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataMacOs.modifierRightControl |
          RawKeyEventDataMacOs.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataMacOs.modifierLeftOption |
          RawKeyEventDataMacOs.modifierOption;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataMacOs.modifierRightOption |
          RawKeyEventDataMacOs.modifierOption;
    }
    final functionKeys = <LogicalKeyboardKey>{
      LogicalKeyboardKey.f1,
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5,
      LogicalKeyboardKey.f6,
      LogicalKeyboardKey.f7,
      LogicalKeyboardKey.f8,
      LogicalKeyboardKey.f9,
      LogicalKeyboardKey.f10,
      LogicalKeyboardKey.f11,
      LogicalKeyboardKey.f12,
      LogicalKeyboardKey.f13,
      LogicalKeyboardKey.f14,
      LogicalKeyboardKey.f15,
      LogicalKeyboardKey.f16,
      LogicalKeyboardKey.f17,
      LogicalKeyboardKey.f18,
      LogicalKeyboardKey.f19,
      LogicalKeyboardKey.f20,
      LogicalKeyboardKey.f21,
    };
    if (pressed.intersection(functionKeys).isNotEmpty) {
      result |= RawKeyEventDataMacOs.modifierFunction;
    }
    if (pressed.intersection(kMacOsNumPadMap.values.toSet()).isNotEmpty) {
      result |= RawKeyEventDataMacOs.modifierNumericPad;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataMacOs.modifierCapsLock;
    }
    return result;
  }

  static int _getIOSModifierFlags(LogicalKeyboardKey newKey, bool isDown) {
    var result = 0;
    final pressed = RawKeyboard.instance.keysPressed;
    if (isDown) {
      pressed.add(newKey);
    } else {
      pressed.remove(newKey);
    }
    if (pressed.contains(LogicalKeyboardKey.shiftLeft)) {
      result |= RawKeyEventDataIos.modifierLeftShift |
          RawKeyEventDataIos.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.shiftRight)) {
      result |= RawKeyEventDataIos.modifierRightShift |
          RawKeyEventDataIos.modifierShift;
    }
    if (pressed.contains(LogicalKeyboardKey.metaLeft)) {
      result |= RawKeyEventDataIos.modifierLeftCommand |
          RawKeyEventDataIos.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.metaRight)) {
      result |= RawKeyEventDataIos.modifierRightCommand |
          RawKeyEventDataIos.modifierCommand;
    }
    if (pressed.contains(LogicalKeyboardKey.controlLeft)) {
      result |= RawKeyEventDataIos.modifierLeftControl |
          RawKeyEventDataIos.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.controlRight)) {
      result |= RawKeyEventDataIos.modifierRightControl |
          RawKeyEventDataIos.modifierControl;
    }
    if (pressed.contains(LogicalKeyboardKey.altLeft)) {
      result |= RawKeyEventDataIos.modifierLeftOption |
          RawKeyEventDataIos.modifierOption;
    }
    if (pressed.contains(LogicalKeyboardKey.altRight)) {
      result |= RawKeyEventDataIos.modifierRightOption |
          RawKeyEventDataIos.modifierOption;
    }
    final functionKeys = <LogicalKeyboardKey>{
      LogicalKeyboardKey.f1,
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5,
      LogicalKeyboardKey.f6,
      LogicalKeyboardKey.f7,
      LogicalKeyboardKey.f8,
      LogicalKeyboardKey.f9,
      LogicalKeyboardKey.f10,
      LogicalKeyboardKey.f11,
      LogicalKeyboardKey.f12,
      LogicalKeyboardKey.f13,
      LogicalKeyboardKey.f14,
      LogicalKeyboardKey.f15,
      LogicalKeyboardKey.f16,
      LogicalKeyboardKey.f17,
      LogicalKeyboardKey.f18,
      LogicalKeyboardKey.f19,
      LogicalKeyboardKey.f20,
      LogicalKeyboardKey.f21,
    };
    if (pressed.intersection(functionKeys).isNotEmpty) {
      result |= RawKeyEventDataIos.modifierFunction;
    }
    if (pressed.intersection(kMacOsNumPadMap.values.toSet()).isNotEmpty) {
      result |= RawKeyEventDataIos.modifierNumericPad;
    }
    if (pressed.contains(LogicalKeyboardKey.capsLock)) {
      result |= RawKeyEventDataIos.modifierCapsLock;
    }
    return result;
  }

  /// Dispatch a message to the platform.
  Future<ByteData?> emitPlatformMessage(String channel, ByteData? data) async {
    final completer = Completer<ByteData>();
    await _binding.defaultBinaryMessenger.handlePlatformMessage(
      channel,
      data,
      completer.complete,
    );
    return completer.future;
  }

  /// Pump the widget tree for the given [duration].
  ///
  /// If [duration] is null, it will pump for a single frame.
  Future<void> pump({Duration? duration}) async {
    if (duration == null) {
      return _binding.endOfFrame;
    }

    final end = clock.now().add(duration);
    while (clock.now().isBefore(end)) {
      await _binding.endOfFrame;
    }
  }

  /// Pump the widget tree and wait for animations to complete.
  Future<void> pumpAndSettle({Duration? timeout}) async {
    final end = clock.now().add(timeout ?? const Duration(seconds: 10));
    do {
      if (clock.now().isAfter(end)) {
        throw Exception('pumpAndSettle timed out');
      }
      await pump();
    } while (_binding.hasScheduledFrame);
  }

  /// Find a node that matches the given text.
  ///
  /// The [text] can be a [String] that can also be used as a [RegExp].
  Future<SemanticsNode?> find(String text, {Duration? timeout}) async {
    var nodes = _findNodes(_semanticsOwner.rootSemanticsNode!, text);

    final end = clock.now().add(timeout ?? const Duration(seconds: 10));
    while (nodes.isEmpty) {
      await pump();
      if (clock.now().isAfter(end)) {
        return null;
      }
      nodes = _findNodes(_semanticsOwner.rootSemanticsNode!, text);
    }

    return nodes.first;
  }

  List<SemanticsNode> _findNodes(SemanticsNode node, String text) {
    final nodes = <SemanticsNode>[];
    node.visitChildren((n) {
      // Add all descendants that match the pattern.
      if (!n.mergeAllDescendantsIntoThisNode) {
        nodes.addAll(_findNodes(n, text));
      }

      // If the node is invisible or has the hidden flag, don't add it.
      if (n.isInvisible || n.hasFlag(SemanticsFlag.isHidden)) {
        return true;
      }

      // Check if the current node matches the pattern on any semantic values.
      // If it does, add it to the list.
      final data = n.getSemanticsData();
      if ([
        data.label,
        data.value,
        data.hint,
        data.tooltip,
      ].any((value) => value == text || RegExp('^$text\$').hasMatch(value))) {
        nodes.add(n);
      }

      return true;
    });

    return nodes;
  }

  /// Retrieve the root repaint boundary.
  RenderRepaintBoundary? getRenderRepaintBoundary() {
    final renderObject = _binding.renderViewElement!.renderObject!;
    RenderRepaintBoundary? boundary;
    void find(RenderObject element) {
      if (boundary != null) return;

      if (element is! RenderRepaintBoundary) {
        return element.visitChildren(find);
      }
      boundary = element;
    }

    if (renderObject is! RenderRepaintBoundary) {
      renderObject.visitChildren(find);
    }
    return boundary;
  }
}

// A tuple of `key` and `location` from Web's `KeyboardEvent` class.
//
// See [RawKeyEventDataWeb]'s `key` and `location` fields for details.
@immutable
class _WebKeyLocationPair {
  const _WebKeyLocationPair(this.key, this.location);
  final String key;
  final int location;
}
