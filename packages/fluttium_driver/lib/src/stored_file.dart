/// {@template stored_file}
/// A file that should be stored at the given [path].
/// {@endtemplate}
class StoredFile {
  /// {@macro stored_file}
  const StoredFile(this.path, this.data);

  /// Path where to store it.
  final String path;

  /// The content of the file in binary.
  final List<int> data;
}
