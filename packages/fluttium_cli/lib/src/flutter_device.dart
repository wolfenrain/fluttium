class FlutterDevice {
  FlutterDevice(Map<String, dynamic> data)
      : id = data['id'] as String,
        name = data['name'] as String,
        isSupported = data['isSupported'] as bool,
        targetPlatform = data['targetPlatform'] as String;

  final String id;

  final String name;

  final bool isSupported;

  final String targetPlatform;
}
