import 'package:equatable/equatable.dart';
import 'package:fluttium_interfaces/src/fluttium/fluttium.dart';

/// {@template action_location}
/// The location of an action.
/// {@endtemplate}
class ActionLocation extends Equatable {
  /// {@macro action_location}
  const ActionLocation({
    this.hosted,
    this.git,
    this.path,
  }) : assert(
          (hosted != null && (git == null || path == null)) ||
              (git != null && (hosted == null || path == null)) ||
              (path != null && (hosted == null || git == null)),
          'Only one of hosted, git, or path can be set.',
        );

  /// {@macro action_location}
  ///
  /// Converts a json map to an [ActionLocation].
  factory ActionLocation.fromJson(dynamic data) {
    if (data is String) {
      return ActionLocation(
        hosted: HostedPath(
          url: 'https://pub.dartlang.org',
          version: VersionConstraint.parse(data),
        ),
      );
    } else if (data is Map<String, dynamic>) {
      if (data.containsKey('hosted')) {
        return ActionLocation(
          hosted: HostedPath(
            url: data['hosted'] as String,
            version: VersionConstraint.parse(data['version'] as String),
          ),
        );
      } else if (data.containsKey('git')) {
        final dynamic git = data['git'];
        if (git is String) {
          return ActionLocation(git: GitPath(url: git));
        } else if (git is Map<String, dynamic>) {
          return ActionLocation(
            git: GitPath(
              url: git['url'] as String,
              ref: git['ref'] as String?,
              path: git['path'] as String?,
            ),
          );
        }
      } else if (data.containsKey('path')) {
        return ActionLocation(path: data['path'] as String);
      }
      throw UnsupportedError('unknown action dependency setup: $data');
    } else {
      throw ArgumentError.value(
        data,
        'data',
        'Must be a String or Map<String, dynamic>',
      );
    }
  }

  /// The hosted path of the action.
  final HostedPath? hosted;

  /// The git path of the action.
  final GitPath? git;

  /// The path of the action.
  final String? path;

  @override
  List<Object?> get props => [hosted, git, path];
}

/// {@template hosted_path}
/// The hosted path of an action.
/// {@endtemplate}
class HostedPath extends Equatable {
  /// {@macro hosted_path}
  const HostedPath({
    required this.url,
    required this.version,
  });

  /// The hosted url.
  final String url;

  /// The version constraint of the action.
  final VersionConstraint version;

  @override
  List<Object?> get props => [url, version];
}

/// {@template git_path}
/// The git path of an action.
/// {@endtemplate}
class GitPath extends Equatable {
  /// {@macro git_path}
  const GitPath({
    required this.url,
    this.ref,
    this.path,
  });

  /// The url of the git repository.
  final String url;

  /// The ref of the git repository.
  final String? ref;

  /// The path where the action is located in the git repository.
  final String? path;

  @override
  List<Object?> get props => [url, ref, path];
}
